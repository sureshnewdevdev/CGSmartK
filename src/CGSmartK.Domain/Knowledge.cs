namespace CGSmartK.Domain;

public enum IngestionStatus { Uploaded, Extracting, Chunking, Embedding, Indexed, Failed, Deleted }
public enum Classification { Public, Internal, Confidential }
public sealed record AccessScope(Classification Classification, IReadOnlySet<string> AllowedGroups)
{
    public bool Allows(Classification maximum, IEnumerable<string> groups) =>
        Classification <= maximum && (AllowedGroups.Count == 0 || AllowedGroups.Overlaps(groups));
}
public sealed class KnowledgeDocument
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public required string OriginalFileName { get; init; }
    public required string BlobName { get; init; }
    public required string Title { get; init; }
    public required string Category { get; init; }
    public required AccessScope Access { get; init; }
    public required string ContentHash { get; init; }
    public required long SizeBytes { get; init; }
    public required string UploaderId { get; init; }
    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public IngestionStatus Status { get; private set; } = IngestionStatus.Uploaded;
    public string? FailureReason { get; private set; }
    public int IndexedChunkCount { get; private set; }
    public void Transition(IngestionStatus status, int count = 0, string? failure = null)
    { Status = status; IndexedChunkCount = count; FailureReason = failure; UpdatedAt = DateTimeOffset.UtcNow; }
}
public sealed record KnowledgeChunk(string Id, Guid DocumentId, string Text, int PageFrom, int PageTo,
    string Section, int Ordinal, string Title, string SourceFileName, string BlobName, string Category,
    AccessScope Access, string ContentHash, DateTimeOffset CreatedAt, float[]? Embedding = null);
public sealed record Citation(string ChunkId, string DocumentTitle, string Section, int PageFrom, int PageTo);
public sealed record RetrievedPassage(KnowledgeChunk Chunk, double Score);
public enum ConfidenceLabel { Low, Medium, High }
public sealed record AuditEvent(string CorrelationId, string Operation, string ActorHash, string Result,
    DateTimeOffset Timestamp, int ItemCount = 0, IReadOnlyList<string>? CitedChunkIds = null);
