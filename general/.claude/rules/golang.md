---
paths:
  - "**/*.go"
---

# Go rules

## Error handling

**Surface an error by wrapping it into the return, not by logging it.** To make a caller or operator see why something failed, return `fmt.Errorf("context: %w", err)`, don't debug/error-log the error just before a bare `return err`. The log fires only at the spot you put it; the wrapped error travels with the value to wherever it's actually handled, and it avoids double-reporting once the caller logs too. A log line sitting in the return path is the wrong place for the reason.
