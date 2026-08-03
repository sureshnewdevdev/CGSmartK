# Repository instructions
- Target .NET 8; run restore, Release build, and all tests before committing.
- Preserve Clean Architecture: Domain has no external dependencies; Application depends only on Domain; Infrastructure implements Application contracts; Web is the composition root.
- Use `DefaultAzureCredential`; never add keys, tokens, secrets, raw prompts, document text, or generated answers to logs.
- All retrieval authorization must be expressed in the Azure AI Search query before prompt construction. Validate citations against retrieved chunks.
- State-changing MVC actions require anti-forgery validation. Production authentication fails closed.
- Live Azure tests and deployment are opt-in. Never create or delete Azure resources from this repository.
