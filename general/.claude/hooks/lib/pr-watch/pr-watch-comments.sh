#!/usr/bin/env bash
# Review-comments watch pipeline, sourced by pr-watch.sh.
# Source this file; do not exec it.
#
# watch_comments()
#   Polls automated review-bot comments tied to HEAD_SHA. When a review with
#   actionable findings (Blocking>0 || Suggestions>0) is posted, notifies the
#   operator and spawns a Claude fixer in a fresh git worktree on a throwaway
#   branch (pr-review-fix-<short_sha>).
#
# Required env (set by the parent script):
#   REPO_DIR REPO_BASENAME URL PLATFORM HEAD_SHA SHORT_SHA BRANCH PR_BRANCH
#   TARGET_SESSION (may be empty -> no spawn)
#   LOG LOG_DIR
# Optional env:
#   PR_WATCH_AUTOFIX=0           -> notify but skip the fixer spawn
#   GITLAB_REVIEW_BOT=other-bot  -> override the gitlab review-bot username
# GitLab-only env (caller computes when PLATFORM=gitlab):
#   HOST PROJ_PATH_ENC MR_IID

watch_comments() {
  local gitlab_bot="${GITLAB_REVIEW_BOT:-sa-mr-bot-mr-bot}"
  local watch_start_epoch attempts i pr_head body review_body=""
  local blocking=0 suggestions=0 findings verdict comments_json
  local late_head review_file pr_verb prompt window_name

  watch_start_epoch=$(date +%s)
  attempts=40   # ~20 minutes at 30s
  i=0
  while [ "$i" -lt "$attempts" ]; do
    case "$PLATFORM" in
      github)
        pr_head=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
        ;;
      gitlab)
        pr_head=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                   | jq -r '.sha // ""' 2>/dev/null || echo "")
        ;;
    esac
    if [ -n "$pr_head" ] && [ "$pr_head" != "$HEAD_SHA" ]; then
      echo "[comments] head moved $HEAD_SHA -> $pr_head, exiting"
      return 0
    fi

    case "$PLATFORM" in
      github)
        comments_json=$(cd "$REPO_DIR" && gh pr view "$URL" --json comments 2>/dev/null || echo '{}')
        body=$(printf '%s' "$comments_json" | jq -r --arg sha "$HEAD_SHA" '
          (.comments // [])
          | map(select(.author.login == "github-actions" and (.body // "" | contains("\"last_reviewed_sha\": \"" + $sha + "\""))))
          | last
          | (.body // "")
        ')
        ;;
      gitlab)
        body=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}/notes?sort=desc&per_page=50" 2>/dev/null \
                | jq -r --argjson start "$watch_start_epoch" --arg user "$gitlab_bot" '
          map(select(
            .author.username == $user
            and ((.body // "") | contains("<!-- ai-review-bot -->"))
            and ((.body // "") | contains("Code Review Summary"))
            and (((.created_at // "1970-01-01T00:00:00Z") | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) > $start)
          ))
          | first
          | (.body // "")
        ')
        ;;
    esac
    if [ -n "$body" ] && [ "$body" != "null" ]; then
      review_body="$body"
      break
    fi
    i=$((i+1))
    sleep 30
  done

  if [ -z "$review_body" ]; then
    echo "[comments] no review found for $HEAD_SHA after $attempts attempts"
    return 0
  fi

  case "$PLATFORM" in
    github)
      blocking=$(printf '%s' "$review_body" | grep -Eo 'Blocking Issues:[* ]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
      suggestions=$(printf '%s' "$review_body" | grep -Eo 'Suggestions:[* ]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
      ;;
    gitlab)
      findings=$(printf '%s' "$review_body" | grep -Eo '\*\*Findings:\*\*[[:space:]]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
      findings=${findings:-0}
      verdict=$(printf '%s' "$review_body" | grep -Eo '\*\*Verdict:\*\*[[:space:]]*[A-Za-z][A-Za-z ]*' | head -n1 | sed -E 's/.*Verdict:\*\*[[:space:]]*//' | tr -d '\r')
      case "$verdict" in
        "Request changes"*|"Block"*|"Reject"*) blocking=$findings; suggestions=0 ;;
        "Approve"*) blocking=0; suggestions=$findings ;;
        *) blocking=0; suggestions=$findings ;;
      esac
      echo "[comments] gitlab review: findings=$findings verdict=\"$verdict\""
      ;;
  esac
  blocking=${blocking:-0}
  suggestions=${suggestions:-0}
  echo "[comments] blocking=$blocking suggestions=$suggestions"

  if [ "$blocking" -eq 0 ] && [ "$suggestions" -eq 0 ]; then
    echo "[comments] no actionable items"
    return 0
  fi

  # If the bot left inline review comments and every one of them is outdated, treat the review as stale and skip spawn.
  local inline_total=0 non_outdated=0
  case "$PLATFORM" in
    github)
      local pr_number repo_path inline_json
      pr_number=$(printf '%s' "$URL" | grep -Eo '[0-9]+$')
      repo_path=$(printf '%s' "$URL" | sed -E 's|^https?://github\.com/([^/]+/[^/]+)/.*|\1|')
      if [ -n "$pr_number" ] && [ -n "$repo_path" ] && command -v gh >/dev/null 2>&1; then
        inline_json=$(gh api "repos/${repo_path}/pulls/${pr_number}/comments?per_page=100" --paginate 2>/dev/null \
                        | jq -s 'add // []' 2>/dev/null || echo '[]')
        inline_total=$(printf '%s' "$inline_json" | jq -r '[.[] | select(.user.login | startswith("github-actions"))] | length' 2>/dev/null || echo 0)
        non_outdated=$(printf '%s' "$inline_json" | jq -r '[.[] | select(.user.login | startswith("github-actions")) | select(.position != null)] | length' 2>/dev/null || echo 0)
      fi
      ;;
    gitlab)
      local discussions_json
      if command -v glab >/dev/null 2>&1; then
        discussions_json=$(glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}/discussions?per_page=100" --paginate 2>/dev/null \
                            | jq -s 'add // []' 2>/dev/null || echo '[]')
        inline_total=$(printf '%s' "$discussions_json" | jq --arg bot "$gitlab_bot" '[.[] | .notes[]? | select(.author.username == $bot and .type == "DiffNote")] | length' 2>/dev/null || echo 0)
        non_outdated=$(printf '%s' "$discussions_json" | jq --arg bot "$gitlab_bot" --arg head "$HEAD_SHA" '[.[] | .notes[]? | select(.author.username == $bot and .type == "DiffNote" and ((.position.head_sha // "") == $head))] | length' 2>/dev/null || echo 0)
      fi
      ;;
  esac
  inline_total=${inline_total:-0}
  non_outdated=${non_outdated:-0}
  echo "[comments] inline bot comments: total=$inline_total non_outdated=$non_outdated"
  if [ "$inline_total" -gt 0 ] && [ "$non_outdated" -eq 0 ]; then
    echo "[comments] all inline bot comments are outdated -- skip spawn"
    return 0
  fi

  # --- Notify (purple) ---
  local title
  if [ "$blocking" -gt 0 ]; then
    title="PR review: $blocking blocking"
  else
    title="PR review: $suggestions suggestion(s)"
  fi
  NOTIFY_TITLE="$title" \
  NOTIFY_BODY="$URL
blocking=$blocking suggestions=$suggestions
spawning fixer in new tmux window
log: $LOG" \
  NOTIFY_SOUND="Submarine" \
  NOTIFY_URGENCY="normal" \
  NOTIFY_BG="#8e24aa" \
    "$HOME/.claude/hooks/notify.sh" custom || true

  # --- Spawn fixer ---
  if [ "${PR_WATCH_AUTOFIX:-1}" != "1" ]; then
    echo "[comments] PR_WATCH_AUTOFIX=0 -- skip spawn"
    return 0
  fi
  if [ -z "${TARGET_SESSION:-}" ]; then
    echo "[comments] no tmux target session -- skip spawn"
    return 0
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "[comments] claude not on PATH -- skip spawn"
    return 0
  fi

  window_name="AUTO-COMMENT-FIX:${REPO_BASENAME}#${SHORT_SHA}"
  if tmux list-windows -a -F '#W' 2>/dev/null | grep -Fxq "$window_name"; then
    echo "[comments] window '$window_name' already exists -- skip spawn"
    return 0
  fi

  # Final head-still-matches guard.
  case "$PLATFORM" in
    github)
      late_head=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
      ;;
    gitlab)
      late_head=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                   | jq -r '.sha // ""' 2>/dev/null || echo "")
      ;;
  esac
  if [ -n "$late_head" ] && [ "$late_head" != "$HEAD_SHA" ]; then
    echo "[comments] head moved $HEAD_SHA -> $late_head before spawn -- skip"
    return 0
  fi

  if ! prelude_create_fix_worktree "$REPO_DIR" "$HEAD_SHA" "pr-review-fix"; then
    echo "[comments] could not create fixer worktree -- skip spawn"
    return 0
  fi

  review_file="$LOG_DIR/pr-comments-review-$(date +%Y%m%d-%H%M%S)-$$.md"
  printf '%s\n' "$review_body" > "$review_file"
  echo "[comments] review body saved to $review_file"

  case "$PLATFORM" in
    github) pr_verb="PR" ;;
    gitlab) pr_verb="MR" ;;
  esac

  read -r -d '' prompt <<EOF || true
A reviewer bot left feedback on ${URL} for commit ${HEAD_SHA}.
Blocking: ${blocking}. Suggestions: ${suggestions}.

The full review body is saved to: ${review_file}

You are running in a fresh git worktree at ${WT_PATH}, on a throwaway branch
${FIX_BRANCH} that was created off ${HEAD_SHA} (the exact commit the bot
reviewed). The operator's main checkout still has ${PR_BRANCH} checked out
elsewhere -- do NOT switch branches and do NOT touch their working tree.

Your job:
1. Confirm pwd is ${WT_PATH} and \`git rev-parse --abbrev-ref HEAD\` prints ${FIX_BRANCH}. If not, stop and tell the user.
2. Read ${review_file} and the cited code locations.
3. For EACH finding (blocking AND suggestion), classify it as either:
     (a) CLEAR -- the fix is obvious, low-risk, and doesn't require a judgment call.
     (b) AMBIGUOUS -- multiple reasonable fixes, design tradeoff, or insufficient context.
4. Apply ALL applicable fixes locally. Build/test (e.g. \`go build ./... && go test ./... -count=1\` for Go).
5. Commit locally on ${FIX_BRANCH}. Separate small commits per finding is fine, or one cohesive commit. Stage only the files you actually changed. Never \`git add -A\`.
6. Print a short summary of: what you changed, which findings were CLEAR vs. AMBIGUOUS, why each AMBIGUOUS item is ambiguous, and (for any phantoms) where you found the bot was wrong. Ring the tmux bell (\`printf '\\a'\`).
7. Ask the user with AskUserQuestion whether to merge ${FIX_BRANCH} into ${PR_BRANCH}. If they say yes, run \`git -C ${REPO_DIR} merge --no-edit ${FIX_BRANCH}\`. On success, tell them the merge landed and remind them to push from ${REPO_DIR} themselves. On failure (dirty working tree in the main checkout, merge conflict, anything else), report the exact git output and stop -- do NOT retry, do NOT \`git merge --abort\` and retry, do NOT push. If they say no, leave the fix branch in place.
8. End your turn. Do NOT push. Do NOT loop back waiting for further input.

Hard rules:
- NEVER push. The operator pushes; you don't.
- Treat every finding as a real claim. Verify it against the code before fixing; if you find the bot is wrong, say so explicitly in the summary instead of "fixing" a phantom.
- One pass only. After the merge prompt, end your turn.
- Never switch branches, never force-push, never rebase, never amend, never \`git add -A\`.
- The only merge you may perform is the single \`git merge --no-edit ${FIX_BRANCH}\` invocation in step 7, only if the user said yes.
- Never skip hooks (--no-verify) or bypass signing.
- Never touch vendor/ or generated files unless that IS the fix.

Operator's main checkout: ${REPO_DIR}
PR branch (operator's checkout): ${PR_BRANCH}
Fix branch (your worktree): ${FIX_BRANCH}
Worktree: ${WT_PATH}

Output: under 200 words at the end, summarize what you changed and whether the merge into ${PR_BRANCH} ran. Confirm you did NOT push.
EOF

  echo "[comments] spawning fixer in tmux session=${TARGET_SESSION} window=${window_name} cwd=${WT_PATH}"
  if tmux new-window -t "${TARGET_SESSION}:" -n "${window_name}" -c "${WT_PATH}" "claude $(printf '%q' "$prompt")"; then
    tmux set-window-option -t "${TARGET_SESSION}:${window_name}" monitor-bell on 2>/dev/null || true
    echo "[comments] fixer launched, monitor-bell enabled"
  else
    echo "[comments] tmux new-window failed (rc=$?)"
  fi
}
