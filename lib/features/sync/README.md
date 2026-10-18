# Sync (offline mode)

Sprint: S6

- `local/`: Drift tables mirroring assets, tickets and work_logs, plus the outbox table
- `sync_service.dart`: pushes the outbox when back online, then pulls changes since `last_synced_at`

See section 5 of the sprint plan ("How offline sync works").

Delete this file once the feature has real code.
