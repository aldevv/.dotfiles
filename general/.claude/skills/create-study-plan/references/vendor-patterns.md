# Vendor patterns: where official study guides live

Priors for the WebSearch step. Not exhaustive. Always verify the page is current and on the vendor's domain before downloading.

| Vendor | Where the official guide lives |
| --- | --- |
| Snowflake (SnowPro) | Two URLs to know. The modern cert page `learn.snowflake.com/en/certifications/<cert-slug>/` shows a "Download Now" button gated by a JS handler (no `.pdf` href in static DOM, so WebFetch sees nothing). The legacy thank-you page `info.snowflake.com/SnowPro-Study-Guide-Form_Updated-Thank-You-Page.html?pdf_name=<NameOfPDF>` still resolves the AEM CDN PDF in the DOM as of 2026: Playwright-navigate, `browser_evaluate` to scan the HTML for `publish-p*.adobeaemcloud.com/.../<NameOfPDF>.pdf`, then hand to `download.sh`. Try the legacy URL first, it's cheaper than wrestling the modern page's JS button. WebSearch will probably surface the modern URL first; don't take that as authoritative for the download. |
| AWS | `aws.amazon.com/certification/certified-<slug>/` links an "Exam Guide" PDF. |
| Google Cloud | `cloud.google.com/certification/guides/<slug>` (HTML exam guide; no PDF). |
| Microsoft (Azure / M365) | `learn.microsoft.com/en-us/credentials/certifications/exams/<exam-id>/` plus the Skills Outline PDF linked from that page. |
| CompTIA | `comptia.org/certifications/<cert>` then "Exam Objectives" PDF. |
| CNCF (CKA / CKAD / CKS) | `github.com/cncf/curriculum` (PDFs in repo). |
| HashiCorp | `developer.hashicorp.com/certifications/<product>` then "Exam objectives" page. |
| Cisco | `learningnetwork.cisco.com/s/<cert>-exam-topics` then blueprint PDF. |

If the cert isn't in the table, fall back to: `WebSearch "<cert name> official exam guide site:<vendor-domain>"` and verify the result is on a vendor-owned domain before downloading.
