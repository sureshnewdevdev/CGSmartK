# Security and threat model

| Threat | Controls |
|---|---|
| Malicious/malformed/encrypted PDF | extension/MIME/signature/length validation, bounded streaming, server blob name, Document Intelligence rejection, private container |
| Prompt injection in PDFs | documents declared untrusted, content never treated as instructions, tool calls unavailable, hostile result validation |
| Data exfiltration | managed identity/RBAC, no public Blob URLs, least-privilege policies, safe logs, strict MCP allowlist |
| Unauthorized retrieval | classification/group OData filter is sent with Search request before prompt context; Application access rules are independently testable |
| Forged citations | generated IDs must exactly match retrieved authorized chunks; title/page come from index metadata, never model output |
| Denial of service | request/file limits, bounded queue/batches, timeouts, retries only for transient calls, cancellation propagation |
| Secret leakage | no keys, `DefaultAzureCredential`, blank endpoint placeholders, sanitized telemetry and errors, no raw prompts/text/answers |

Production authentication fails closed. Development identities cannot activate outside Development. Anti-forgery protects state changes; HTTPS/HSTS, secure platform cookies, CSP, framing/MIME/referrer headers, Razor encoding, and input limits reduce web risk. Administrators must confirm deletion. Classification values and groups must be governed by the tenant owner.
