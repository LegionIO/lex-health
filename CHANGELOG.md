# Changelog

## [0.2.1] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies
- Replace direct Legion::JSON.dump calls with json_dump helper in runners/health.rb
- Update spec_helper with real sub-gem helper stubs

## [0.2.0] - 2026-03-18

### Fixed
- `active` column now uses boolean `true` instead of integer `1` (PostgreSQL compatibility)
- Watchdog message routing key changed from `'health'` to `'node.health'` to match queue binding
- Added `require 'time'` for `Time.parse`
- Nil guard on `updated` timestamp in back-in-time comparison
- TOCTOU race condition on concurrent heartbeat inserts (rescue UniqueConstraintViolation)
- `delete` method nil guard for nonexistent nodes
- `mark_workers_offline` now clears `health_node` on expired workers

### Changed
- Entry point `data_required?` is now `self.` (class method) matching framework expectation

## [0.1.8] - 2026-03-17

### Fixed
- Watchdog `expire` guards against missing `Legion::Data::Model::Node` constant before use, returning an error hash when the model is unavailable

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
