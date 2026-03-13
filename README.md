# lex-health

Node health monitoring for [LegionIO](https://github.com/LegionIO/LegionIO). Reads heartbeat messages from cluster nodes, updates the database with their health status, and runs a watchdog actor for detecting stale or dead nodes.

## Installation

```bash
gem install lex-health
```

## Functions

- **Health** - Process incoming heartbeat messages and update node status
- **Watchdog** - Monitor for stale nodes and flag them

## Requirements

- Ruby >= 3.4
- [LegionIO](https://github.com/LegionIO/LegionIO) framework

## License

MIT
