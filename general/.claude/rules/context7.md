Use Context7 MCP to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service, even well-known ones. Covers API syntax, configuration, version migration, library-specific debugging, setup, and CLI usage. Use even when you think you know the answer; training data may be stale. Prefer over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Start with `resolve-library-id` using the library name and the user's question, unless the user gave an exact `/org/project` ID.
2. Pick the best match by exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score. Retry with alternate names if results look wrong (e.g. "next.js" not "nextjs"). Use version-specific IDs when a version is mentioned.
3. `query-docs` with the selected ID and the user's full question (not single words).
4. Answer using the fetched docs.
