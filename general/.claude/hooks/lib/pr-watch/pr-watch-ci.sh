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
      else
        # rc != 0 means failure somewhere. Don't trust the watch output to be
        # parseable (--watch --fail-fast can print non-tab-separated rows or
        # ANSI-coloured output that breaks the awk filter). Go to the API as
        # the ground truth.
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
          echo "[ci] gh pr checks rc=$rc but api shows no failures for $HEAD_SHA -- treating as tool error or flake"
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
  prelude_trust_worktree "$WT_PATH"

  local window_name="AUTO-CI-FIX:${REPO_BASENAME}#${SHORT_SHA}"
  local log_cmd
  case "$PLATFORM" in
    github) log_cmd="gh run view <id> --log-failed | tail -200" ;;
    gitlab) log_cmd="glab ci view <job-id>  # or 'glab ci trace <job-id>' for raw logs" ;;
  esac

  # The pr-ci-fix skill owns the workflow body. The hook only ships the
  # context the skill needs as its first user message.
  local prompt
  read -r -d '' prompt <<EOF || true
/pr-ci-fix

URL: ${URL}
Platform: ${PLATFORM}
Commit: ${HEAD_SHA}
Failing: ${failed}
Worktree: ${WT_PATH}
Fix branch: ${FIX_BRANCH}
Main checkout: ${REPO_DIR}
PR branch: ${PR_BRANCH}
Hook log: ${LOG}
Log command: ${log_cmd}
EOF

  echo "[ci] spawning fixer in tmux session=${TARGET_SESSION} window=${window_name} cwd=${WT_PATH}"
  if tmux new-window -t "${TARGET_SESSION}:" -n "${window_name}" -c "${WT_PATH}" "claude --dangerously-skip-permissions $(printf '%q' "$prompt")"; then
    echo "[ci] fixer launched"
  else
    echo "[ci] tmux new-window failed (rc=$?)"
  fi
}
