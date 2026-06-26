# Trigger authoring

Every `**Read when:**` clause must be broad enough to catch every situation it should fire on AND concrete enough that the match is unambiguous. Err broader: a wasted load is fine, a silently-missed load is not.

**Completeness beats brevity.** A good trigger carries all the information Claude needs to recognize the load moment, even if that takes multiple lines or a bulleted list. Don't truncate a trigger to fit a one-liner if the result loses signals. A complex file with many entry points gets a complex trigger; that's fine.

**Good triggers tie to observable signals:**
- file paths or extensions about to be edited (`editing any .go file`, `editing pkg/config/config.go`)
- commands about to run (`running ANY gh subcommand`, `running pass otp`)
- syntactic content in the tool call (`Write/Edit with //, #, /* in new content`)
- specific tool calls (`before any gh pr create`)
- explicit user phrases (`given a Linear ticket URL/ID`)

**Bad triggers rely on introspection or abstract categories:**
- `implementing a feature` (no signal, too abstract)
- `working with PRs` (vague self-categorization)
- `about to add a comment` (introspective, fires too late: Claude has already composed the comment in the Edit payload before the trigger registers)
- `considering whether X applies` (only loads after the work is done)
- `when in doubt, read this` (no concrete moment to anchor to)

**Fix recipe when a trigger is ignored:** replace the introspective phrasing with the file/tool/syntax signal that was actually observable at the moment the trigger should have fired.
