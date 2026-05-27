#!/usr/bin/env bash
# CI watch pipeline, sourced by pr-watch.sh.
# Source this file; do not exec it.
#
# watch_ci()
#   Polls CI on the open PR/MR until it resolves, notifies the operator, and
#   on failure tied to HEAD_SHA spawns a Claude fixer in a fresh git worktree
#   on a throwaway branch (ci-fix-<short_sha>).
#
# Required env (set by the parent script):
#   REPO_DIR REPO_BASENAME URL PLATFORM HEAD_SHA SHORT_SHA BRANCH PR_BRANCH
#   TARGET_SESSION (may be empty -> no spawn)
#   LOG
# Optional env:
#   PR_WATCH_AUTOFIX=0  -> notify but skip the fixer spawn
# GitLab-only env (caller computes when PLATFORM=gitlab):
#   HOST PROJ_PATH_ENC MR_IID

watch_ci() {
  local status="" failed="" out rc
  local new_head nwo sha_failed
  local mr_num pipeline_status pipeline_sha mr_json i

  case "$PLATFORM" in
    github)
      out=$(gh pr checks "$URL" --watch --fail-fast --interval 15 2>&1)
      rc=$?
      echo "[ci] gh pr checks rc=$rc"
      if [ "$rc" -eq 0 ]; then
        status="pass"
      elif ! printf '%s\n' "$out" | awk -F'\t' '$2 == "fail" || $2 == "cancel" { found=1 } END { exit !found }'; then
        echo "[ci] no failed-check rows -- treating as tool error"
        return 0
      else
        new_head=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
        if [ -n "$new_head" ] && [ "$new_head" != "$HEAD_SHA" ]; then
          echo "[ci] head moved $HEAD_SHA -> $new_head, skipping"
          return 0
        fi
        nwo=$(printf '%s' "$URL" | sed -E 's|^https?://[^/]+/([^/]+/[^/]+)/.*$|\1|')
        sha_failed=$(gh api "repos/$nwo/commits/$HEAD_SHA/check-runs?per_page=100" \
          --jq '.check_runs[] | select(.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out") | .name' \
          2>/dev/null | paste -sd, -)
        if [ -z "$sha_failed" ]; then
          sha_failed=$(gh api "repos/$nwo/commits/$HEAD_SHA/status" \
            --jq '.statuses[] | select(.state == "failure" or .state == "error") | .context' \
            2>/dev/null | paste -sd, -)
        fi
        if [ -z "$sha_failed" ]; then
          echo "[ci] failures not tied to head sha -- skipping"
          return 0
        fi
        status="fail"
        failed="$sha_failed"
      fi
      ;;

    gitlab)
      mr_num=$(echo "$URL" | grep -Eo '[0-9]+$')
      if [ -z "$mr_num" ]; then
        echo "[ci] could not extract MR number"
        return 0
      fi
      i=0
      while [ "$i" -lt 480 ]; do
        mr_json=$(cd "$REPO_DIR" && glab mr view "$mr_num" --output json 2>/dev/null || echo '{}')
        pipeline_status=$(printf '%s' "$mr_json" | jq -r '.head_pipeline.status // .pipeline.status // ""')
        pipeline_sha=$(printf '%s' "$mr_json" | jq -r '.head_pipeline.sha // .pipeline.sha // ""')
        if [ -n "$pipeline_sha" ] && [ "$pipeline_sha" != "$HEAD_SHA" ]; then
          echo "[ci] pipeline sha=$pipeline_sha != head=$HEAD_SHA, skipping"
          return 0
        fi
        case "$pipeline_status" in
          success)         status="pass"; break ;;
          failed|canceled) status="fail"; break ;;
          running|pending|preparing|created|scheduled|waiting_for_resource|manual|"") sleep 15 ;;
          *) sleep 15 ;;
        esac
        i=$((i+1))
      done
      if [ "$status" = "fail" ]; then
        failed=$(cd "$REPO_DIR" && glab ci status --branch "$BRANCH" 2>/dev/null \
                  | awk '/failed/ { print $1 }' \
                  | paste -sd, -)
        [ -z "$failed" ] && failed="(pipeline failed; could not enumerate failed jobs)"
      fi
      ;;
  esac

  [ -z "$status" ] && return 0
  echo "[ci] status=$status failed='$failed'"

  # --- Notify ---
  if [ "$status" = "pass" ]; then
    NOTIFY_TITLE="PR CI passed" \
    NOTIFY_BODY="$URL
all checks green
log: $LOG" \
    NOTIFY_SOUND="Glass" \
    NOTIFY_URGENCY="low" \
    NOTIFY_BG="#2e7d32" \
      "$HOME/.claude/hooks/notify.sh" custom || true
    return 0
  fi

  NOTIFY_TITLE="PR CI failed" \
  NOTIFY_BODY="$URL
failing: $failed
spawning fixer in new tmux window
log: $LOG" \
  NOTIFY_SOUND="Basso" \
  NOTIFY_URGENCY="critical" \
  NOTIFY_BG="#c62828" \
    "$HOME/.claude/hooks/notify.sh" custom || true

  # --- Spawn fixer ---
  if [ "${PR_WATCH_AUTOFIX:-1}" != "1" ]; then
    echo "[ci] PR_WATCH_AUTOFIX=0 -- skip spawn"
    return 0
  fi
  if [ -z "${TARGET_SESSION:-}" ]; then
    echo "[ci] no tmux target session -- skip spawn"
    return 0
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "[ci] claude not on PATH -- skip spawn"
    return 0
  fi

  if ! prelude_create_fix_worktree "$REPO_DIR" "$HEAD_SHA" "ci-fix"; then
    echo "[ci] could not create fixer worktree -- skip spawn"
    return 0
  fi

  local window_name="AUTO-CI-FIX:${REPO_BASENAME}#${SHORT_SHA}"
  local log_cmd
  case "$PLATFORM" in
    github) log_cmd="gh run view <id> --log-failed | tail -200" ;;
    gitlab) log_cmd="glab ci view <job-id>  # or 'glab ci trace <job-id>' for raw logs" ;;
  esac

  local prompt
  read -r -d '' prompt <<EOF || true
A CI failure was detected on ${URL} (platform: ${PLATFORM}) for commit ${HEAD_SHA}.
Failing checks/jobs: ${failed}.

You are running in a fresh git worktree at ${WT_PATH}, on a throwaway branch
${FIX_BRANCH} that was created off ${HEAD_SHA} (the same commit the failing CI
ran against). The operator's main checkout still has ${PR_BRANCH} checked out
elsewhere -- do NOT switch branches and do NOT touch their working tree.

Your job is to attempt a single, minimal fix.

Workflow:
1. Confirm pwd is ${WT_PATH} and \`git rev-parse --abbrev-ref HEAD\` prints ${FIX_BRANCH}. If not, stop and tell the user.
2. For each failing check/job, fetch its failed log lines: ${log_cmd}.
3. Diagnose the root cause. Apply the SMALLEST possible fix. Do not refactor, do not rework architecture, do not touch unrelated files.
4. If the failure looks like a flake (intermittent timeout, network blip, vendor-side outage, no clear code-level cause), do NOT edit code or re-run anything. Stop and tell the user it looks like a flake.
5. Build/test locally for whatever language the repo uses (e.g. \`go build ./... && go test ./... -count=1\` for Go).
6. Commit locally on ${FIX_BRANCH} with a short imperative message ("fix <thing>"). Stage only the files you actually changed. Never use \`git add -A\`.
7. Print a short summary of what you changed and ring the tmux bell (\`printf '\\a'\`).
8. Ask the user with AskUserQuestion whether to merge ${FIX_BRANCH} into ${PR_BRANCH}. If they say yes, run \`git -C ${REPO_DIR} merge --no-edit ${FIX_BRANCH}\`. On success, tell them the merge landed and remind them to push from ${REPO_DIR} themselves. On failure (dirty working tree in the main checkout, merge conflict, anything else), report the exact git output and stop -- do NOT retry, do NOT \`git merge --abort\` and retry, do NOT push. If they say no, leave the fix branch in place.
9. End your turn. Do NOT push. Do NOT re-run CI. Do NOT loop back waiting for further input.

Hard rules:
- Never push. Never open a new PR or MR. Never change reviewers, labels, or assignees.
- Never switch branches, never rebase, never force-push, never amend.
- The only merge you may perform is the single \`git merge --no-edit ${FIX_BRANCH}\` invocation in step 8, only if the user said yes.
- Never touch vendor/ or generated files unless that IS the bug.
- Never skip hooks (--no-verify) or bypass signing.
- One fix attempt total. After the merge prompt, end your turn.

URL: ${URL}
Operator's main checkout: ${REPO_DIR}
PR branch (operator's checkout): ${PR_BRANCH}
Fix branch (your worktree): ${FIX_BRANCH}
Worktree: ${WT_PATH}
Failing (comma-separated): ${failed}
Hook log for context: ${LOG}
EOF

  echo "[ci] spawning fixer in tmux session=${TARGET_SESSION} window=${window_name} cwd=${WT_PATH}"
  if tmux new-window -t "${TARGET_SESSION}:" -n "${window_name}" -c "${WT_PATH}" "claude $(printf '%q' "$prompt")"; then
    echo "[ci] fixer launched"
  else
    echo "[ci] tmux new-window failed (rc=$?)"
  fi
}
