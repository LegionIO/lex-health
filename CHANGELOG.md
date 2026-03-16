# Changelog

## [0.1.7] - 2026-03-16

### Fixed
- Watchdog `expire` now uses cross-DB Sequel DSL instead of MySQL-only `DATE_SUB(SYSDATE(), ...)` SQL

### Added
- Health runner stores `metrics`, `hosted_worker_ids`, and `version` on node records from heartbeat payload
- Health runner updates digital worker `health_status` to `online` and sets `last_heartbeat_at`/`health_node` for hosted workers
- Health runner marks workers as `unknown` when no longer reported by their hosting node
- Watchdog marks digital workers as `offline` when their hosting node times out

## [0.1.6] - 2026-03-13

### Added
- Initial release
