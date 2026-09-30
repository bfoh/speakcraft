# Database boundary

Sprint 1 has no server database. Mobile local schema version 1 is created by `mobile/lib/core/storage/sqlite_progress_store.dart` and tested against a real SQLite file. Future local schema changes must add an upgrade migration. Add server migrations here only when a concrete feature requires server persistence.
