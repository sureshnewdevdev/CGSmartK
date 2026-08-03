using CGSmartK.Domain;
namespace CGSmartK.Application;

/// <summary>Embeds a question and delegates to retrieval that applies authorization in its data-plane query.</summary>
public sealed class KnowledgeRetrievalAgent(IEmbeddingService embeddings, IKnowledgeIndex index)
{
    public async Task<IReadOnlyList<RetrievedPassage>> RetrieveAsync(string question, UserAccessContext user, CancellationToken ct) =>
        await index.SearchAsync(question, await embeddings.EmbedAsync(question, ct), user, ct);
}
/// <summary>Deterministically selects a bounded workflow; it never starts an autonomous tool loop.</summary>
public sealed class WorkflowOrchestrationAgent
{
    public static WorkflowKind Route(string requested) => requested.Trim().ToLowerInvariant() switch
    { "summary" or "summarize" => WorkflowKind.Summary, "draft" or "draftarticle" => WorkflowKind.DraftArticle, _ => WorkflowKind.Answer };
}
/// <summary>Checks generated citation identifiers and injection indicators before display.</summary>
public sealed class PolicyComplianceAgent
{
    public static ValidationResult Validate(GeneratedAnswer candidate, IReadOnlyList<RetrievedPassage> authorized) =>
        candidate.CitedChunkIds.Count > 0 && candidate.CitedChunkIds.All(id => authorized.Any(p => p.Chunk.Id == id)) && !PromptSecurity.LooksHostile(candidate.Text)
            ? new(true, null) : new(false, "The generated response was not grounded in authorized evidence.");
}
/// <summary>Produces summary/draft candidates through the same grounded generator used for answers.</summary>
public sealed class DocumentationAgent(IAnswerGenerator generator)
{
    public Task<GeneratedAnswer> SummarizeAsync(string request, IReadOnlyList<RetrievedPassage> context, CancellationToken ct) => generator.GenerateAsync(request, context, WorkflowKind.Summary, ct);
    public Task<GeneratedAnswer> DraftAsync(string request, IReadOnlyList<RetrievedPassage> context, CancellationToken ct) => generator.GenerateAsync(request, context, WorkflowKind.DraftArticle, ct);
}
/// <summary>Provides the only application entry point to allowlisted MCP tools.</summary>
public sealed class McpIntegrationAgent(IMcpToolClient client)
{
    public bool IsAvailable => client.IsAvailable;
    public Task<string> InvokeAsync(string tool, IReadOnlyDictionary<string,string> input, UserAccessContext user, CancellationToken ct) => client.InvokeAsync(tool, input, user, ct);
}
