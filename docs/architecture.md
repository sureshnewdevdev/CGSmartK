# Architecture

Domain owns documents, chunks, scopes, citations, statuses, confidence, and audit concepts. Application owns upload, deterministic workflow routing, pre-retrieval authorization filters, chunking, grounding, and ports. Infrastructure implements private Blob/metadata persistence, Document Intelligence layout extraction, Azure OpenAI embeddings/chat, Search schema/hybrid retrieval, managed identity, bounded ingestion, privacy-safe audit state, resilience, and disabled MCP. Web composes MVC, policies, anti-forgery, health, security headers, and accessible views.

Ingestion persists the PDF and metadata before enqueueing. Each stage persists status. A document becomes `Indexed` only after expected chunks upload; partial dependency failure becomes `Failed` while preserving safe metadata. Search uses HNSW (1536 configurable dimensions), semantic title/content configuration, keyword plus vector query, classification/group OData filter, score threshold, and per-document diversification.

The answer workflow is validate → authorize → embed → filtered retrieve → grounded generation → citation/prompt-injection validation → confidence → audit. No passages means a fixed insufficient-evidence response. Generation/dependency/validation failure cannot fall back to model knowledge. Documentation summary/draft uses the same authorized retrieval; drafts are labeled by prompt. Semantic unavailability should be handled operationally by retrying without semantic query while retaining hybrid/vector and ACL filtering.

Confidence formula: Low when validation fails, no passages, or best score <0.62; Medium when validated and best score is 0.62–0.819999; High when validated, best score ≥0.82, and at least two passages. It is never model-supplied.
