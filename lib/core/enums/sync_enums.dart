/// VitalSync — Sync Enums.
library;

/// Sync operation types.
enum SyncOperation { insert, update, delete }

/// Sync queue status.
enum SyncQueueStatus { pending, inProgress, failed, completed }
