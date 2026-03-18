# lex-health: Node Health Monitoring for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that reads heartbeat messages from cluster nodes and updates the database with their health status. Includes a watchdog actor for detecting and expiring stale/dead nodes. Requires `legion-data` (`data_required? true`).

**GitHub**: https://github.com/LegionIO/lex-health
**License**: MIT
**Version**: 0.2.0

## Architecture

```
Legion::Extensions::Health
├── Actors/
│   ├── Health             # Subscription actor: processes incoming heartbeat messages
│   └── Watchdog           # Every actor (every 5s): scans for stale nodes, calls expire
├── Runners/
│   ├── Health             # update, insert, delete node records in DB; updates digital worker health status
│   └── Watchdog           # expire: marks nodes as unknown if heartbeat is stale; marks hosted workers offline
└── Transport/
    ├── Exchanges/Node     # Node communication exchange
    ├── Queues/Health      # Health check queue
    └── Messages/Watchdog  # NodeHealth message for expiring stale nodes
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/health.rb` | Entry point, extension registration (`data_required? true`) |
| `lib/legion/extensions/health/runners/health.rb` | Heartbeat processing: update/insert/delete node DB records, update digital worker health status |
| `lib/legion/extensions/health/runners/watchdog.rb` | Stale node detection: expire nodes with heartbeat older than `expire_time` seconds, mark hosted workers offline |
| `lib/legion/extensions/health/actors/health.rb` | AMQP subscription actor |
| `lib/legion/extensions/health/actors/watchdog.rb` | Periodic watchdog actor |

## Runner Details

**Health runner**: `update(hostname:, **opts)` - upserts node status. Uses timestamp comparison to avoid back-in-time updates. Stores `metrics` (JSON text), `hosted_worker_ids` (JSON text), and `version` on the node record. Calls `update_worker_health` to mark hosted digital workers as `online` with `last_heartbeat_at` and `health_node`, and marks workers no longer reported by the node as `unknown`. `insert` and `delete` are also available.

**Watchdog runner**: `expire(expire_time: 60, **_opts)` - queries for healthy nodes with `updated` older than `expire_time` seconds (default: 60) using cross-DB Sequel DSL. Publishes `NodeHealth` messages to transition them to `unknown`. Calls `mark_workers_offline` to set `health_status: 'offline'` on all digital workers hosted by the expired node. The actor runs every 5 seconds (controlled by `time = 5` in the actor), independently of the `expire_time` threshold.

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
