namespace CGSmartK.Application;

/// <summary>
/// Queues documents for asynchronous ingestion.
/// </summary>
public interface IIngestionChannel
{
    ValueTask EnqueueAsync(Guid documentId, CancellationToken cancellationToken);

    IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken cancellationToken);
}
