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
  local late_head review_file pr_verb prompt prompt_head prompt_tail apply_policy window_name comment_hash

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

  comment_hash=$(printf '%s' "$review_body" | sha256sum 2>/dev/null | cut -c1-8)
  comment_hash=${comment_hash:-nohash}
  window_name="AUTO-COMMENT-FIX:${REPO_BASENAME}#${SHORT_SHA}-${comment_hash}"
  if tmux list-windows -a -F '#W' 2>/dev/null | grep -Fxq "$window_name"; then
    echo "[comments] window '$window_name' already exists (same comment hash) -- skip spawn"
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
  prelude_trust_worktree "$WT_PATH"

  review_file="$LOG_DIR/pr-comments-review-$(date +%Y%m%d-%H%M%S)-$$.md"
  printf '%s\n' "$review_body" > "$review_file"
  echo "[comments] review body saved to $review_file"

  if [ "$blocking" -gt 0 ]; then
    apply_policy="Blocking=${blocking}. Apply ALL surviving findings (blocking and suggestion) in one pass, no per-finding confirmation."
  else
    apply_policy="Blocking=0, Suggestions=${suggestions}. For EACH surviving finding, use AskUserQuestion BEFORE making any change. Group closely related findings into one question; otherwise ask per finding. Only apply findings the user approves."
  fi

  # The auto-pr-comment-fix skill owns the workflow body. The hook only ships the
  # context block + the review body as the skill's first user message.
  read -r -d '' prompt <<EOF || true
/auto-pr-comment-fix

URL: ${URL}
Platform: ${PLATFORM}
Commit: ${HEAD_SHA}
Blocking: ${blocking}
Suggestions: ${suggestions}
Apply policy: ${apply_policy}
Worktree: ${WT_PATH}
Fix branch: ${FIX_BRANCH}
Main checkout: ${REPO_DIR}
PR branch: ${PR_BRANCH}
Review body file: ${review_file}
---
${review_body}
---
EOF

  echo "[comments] spawning fixer in tmux session=${TARGET_SESSION} window=${window_name} cwd=${WT_PATH}"
  if tmux new-window -t "${TARGET_SESSION}:" -n "${window_name}" -c "${WT_PATH}" "claude --dangerously-skip-permissions $(printf '%q' "$prompt")"; then
    tmux set-window-option -t "${TARGET_SESSION}:${window_name}" monitor-bell on 2>/dev/null || true
    echo "[comments] fixer launched, monitor-bell enabled"
  else
    echo "[comments] tmux new-window failed (rc=$?)"
  fi
}
