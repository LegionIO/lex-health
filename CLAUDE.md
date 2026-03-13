# lex-health: Node Health Monitoring for LegionIO

**Repository Level 3 Documentation**
- **Category**: `/Users/miverso2/rubymine/legion/extensions/CLAUDE.md`

## Purpose

Legion Extension that reads heartbeat messages from cluster nodes and updates the database with their health status. Includes a watchdog actor for detecting stale/dead nodes.

**License**: MIT

## Architecture

```
Legion::Extensions::Health
├── Actors/
│   ├── Health             # Processes incoming heartbeat messages
│   └── Watchdog           # Monitors for stale nodes
├── Runners/
│   ├── Health             # Heartbeat processing logic
│   └── Watchdog           # Stale node detection logic
└── Transport/
    ├── Exchanges/Node     # Node communication exchange
    ├── Queues/Health      # Health check queue
    └── Messages/Watchdog  # Watchdog message format
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/health.rb` | Entry point, extension registration |
| `lib/legion/extensions/health/actors/health.rb` | Heartbeat processing actor |
| `lib/legion/extensions/health/actors/watchdog.rb` | Dead node detection actor |
| `lib/legion/extensions/health/runners/` | Business logic |

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
