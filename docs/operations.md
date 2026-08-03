# Operations

Use `/health/live` for process liveness and `/health/ready` for categorized readiness. Application Insights receives ASP.NET telemetry and structured ingestion/retrieval events; search by correlation/document ID. Never add document text, prompts, full answers, tokens, or raw identities to telemetry.

For failed ingestion, inspect safe failure/status metadata, resolve RBAC/service/PDF issue, and choose Re-index. Restarts preserve PDFs/status but may lose in-memory jobs; administrators can requeue Uploaded/Failed records. Deletion requires confirmation and removes indexed chunks before the source PDF. To roll back an app release, redeploy the prior package; do not roll back by deleting the index or storage. Incompatible index schemas require a planned side-by-side index and configuration switch.

B1/single instance limitations: bounded local queue, no cross-instance coordination, volatile audit lookup, and sequential embedding. Production scale-out should use a durable queue, durable audit store, worker service, distributed locking, rate controls, and staged index aliases. Outages preserve source data and produce safe unavailable/insufficient responses.
