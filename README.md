# lex-health

Node health monitoring for [LegionIO](https://github.com/LegionIO/LegionIO). Reads heartbeat messages from cluster nodes, updates the database with their health status, and runs a watchdog actor for detecting stale or dead nodes.

## Installation

```bash
gem install lex-health
```

## Functions

- **Health** - Process incoming heartbeat messages and update node status in the database
- **Watchdog** - Periodically scan for nodes with stale heartbeats and expire them to `unknown` status

## How It Works

The Health runner receives heartbeat messages published by `lex-node` and upserts node records in the database. It uses timestamp comparison to prevent out-of-order updates from rolling back newer status.

The Watchdog actor runs every 5 seconds and queries for healthy nodes whose last heartbeat timestamp is older than `expire_time` seconds (default: 60 seconds). Those nodes are transitioned to `unknown` by publishing `NodeHealth` messages.

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework
- `legion-data` (database required)

## License

MIT
