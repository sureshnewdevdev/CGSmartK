using CGSmartK.Domain;
namespace CGSmartK.Application;

public sealed record UserAccessContext(string SubjectId, IReadOnlySet<string> Groups, Classification MaximumClassification, bool IsAdministrator);
public sealed record UploadDocumentCommand(string FileName, string ContentType, long Length, Stream Content, string Title,
    string Category, Classification Classification, IReadOnlySet<string> AllowedGroups, string UploaderId);
public sealed record ChatRequest(string Question, UserAccessContext User, string CorrelationId, WorkflowKind Workflow = WorkflowKind.Answer);
public sealed record ChatResponse(string Answer, IReadOnlyList<Citation> Citations, DateTimeOffset Timestamp,
    ConfidenceLabel Confidence, string CorrelationId, bool InsufficientEvidence, bool Validated);
public enum WorkflowKind { Answer, Summary, DraftArticle }
public sealed record GeneratedAnswer(string Text, IReadOnlyList<string> CitedChunkIds);
public sealed record ValidationResult(bool IsValid, string? SafeReason);
public sealed record ExtractedPage(int PageNumber, string Text, string Section);
public sealed record OperationStatus(string CorrelationId, string Operation, string State, DateTimeOffset UpdatedAt, int ItemCount);
public interface IDocumentRepository { Task<KnowledgeDocument?> FindByHashAsync(string hash, CancellationToken ct); Task SaveAsync(KnowledgeDocument document, Stream content, CancellationToken ct); Task<KnowledgeDocument?> GetAsync(Guid id, CancellationToken ct); Task<IReadOnlyList<KnowledgeDocument>> ListAsync(CancellationToken ct); Task UpdateMetadataAsync(KnowledgeDocument document, CancellationToken ct); Task DeleteAsync(KnowledgeDocument document, CancellationToken ct); }
public interface IDocumentExtractor { Task<IReadOnlyList<ExtractedPage>> ExtractAsync(KnowledgeDocument document, CancellationToken ct); }
public interface IEmbeddingService { Task<float[]> EmbedAsync(string text, CancellationToken ct); }
public interface IKnowledgeIndex { Task EnsureAsync(CancellationToken ct); Task IndexAsync(IReadOnlyList<KnowledgeChunk> chunks, CancellationToken ct); Task DeleteDocumentAsync(Guid documentId, CancellationToken ct); Task<IReadOnlyList<RetrievedPassage>> SearchAsync(string query, float[] vector, UserAccessContext user, CancellationToken ct); }
public interface IAnswerGenerator { Task<GeneratedAnswer> GenerateAsync(string question, IReadOnlyList<RetrievedPassage> context, WorkflowKind workflow, CancellationToken ct); }
public interface IAuditStore { Task WriteAsync(AuditEvent audit, CancellationToken ct); Task<OperationStatus?> GetAsync(string correlationId, CancellationToken ct); }
public interface IMcpToolClient { bool IsAvailable { get; } Task<string> InvokeAsync(string tool, IReadOnlyDictionary<string,string> input, UserAccessContext user, CancellationToken ct); }
public interface IKnowledgeService { Task<KnowledgeDocument> UploadAsync(UploadDocumentCommand command, CancellationToken ct); Task ReindexAsync(Guid id, CancellationToken ct); Task DeleteAsync(Guid id, bool confirmed, CancellationToken ct); }
public interface IAssistantService { Task<ChatResponse> AskAsync(ChatRequest request, CancellationToken ct); }
