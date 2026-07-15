# Read the whole doc page, not just the code example

- If the vendor offers a Postman collection or OpenAPI spec, grab it and use that as the source of truth. Doc pages can lag or skip details the spec covers.
- Before swapping endpoints, compare what the old one does against what the new one's docs say it does. A similar-looking endpoint is not evidence.
- The gotchas (side effects, tier gates, what happens on partial failure) sit in the paragraphs around the example, not in it. Look for words like "also removes", "also disables", "in addition", "as well".
- Every part of the request has to match the docs: content-type, headers, query params, body shape, identifier form. If anything in our code or config doesn't match the docs, tell me in chat before you commit. "It works against this tenant" is not enough.
- Leave a comment with the doc-page URL next to any third-party API call. Saves the next reader a grep, and makes the "read the prose" step above trivial to repeat.
- Put third-party URLs together in one constants file (`url.go`, `endpoints.go`, `urls.ts`, etc.) with the doc-page URL as a comment above each. One place to scan, easy to keep in sync with the docs.
- One function per endpoint beats one generic helper that handles all endpoints. Redundant but easier to read and debug; when one endpoint behaves differently, you don't have to unwind a parameterized helper.
