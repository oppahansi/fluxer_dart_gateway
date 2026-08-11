# fluxer_dart_gateway

WebSocket gateway client for the [fluxer_dart](https://github.com/oppahansi/fluxer_dart) ecosystem.

Everything here was verified against Fluxer's own source
(`fluxerapp/fluxer` on GitHub), since Fluxer's public gateway docs are
still unwritten placeholders: the reference client's TS event handlers
(`fluxer_app/src/features/**/events/*.ts`) for dispatch payload shapes,
and the gateway server's own Erlang source
(`fluxer_gateway/src/gateway/gateway_sharding.erl`,
`gateway_handler_identify.erl`) for the IDENTIFY/sharding wire format.

## Design

Structured around an **explicit connection state machine**
(`Disconnected → Connecting → Identifying|Resuming → Connected →
Reconnecting → Closed`) for exhaustive `switch` handling of every
transition. Incoming events decode into a sealed `GatewayEvent` hierarchy,
also exhaustively `switch`-able.

## What's here

- `GatewayOpcode` / `GatewayCloseCode` — the full verified opcode (0–16)
  and close code (4000–4012) tables.
- `GatewayConnectionState` — the sealed state machine.
- `HeartbeatManager` — jittered heartbeat scheduling + ack tracking,
  matching Fluxer's own jitter formula (`base = max(1000, interval*0.8)`,
  `jitter = min(1500, interval*0.05)`).
- `GatewayEvent` — sealed dispatch event hierarchy covering 22 typed
  events (session lifecycle, message create/update/delete/reactions/
  typing, guild/role/member/ban CRUD, channel CRUD), with an
  `UnknownDispatchEvent` fallback for event names not yet modeled so
  those messages don't crash the connection.
- `GatewayConnection` — the per-shard orchestrator: HELLO →
  IDENTIFY/RESUME → heartbeat loop → typed dispatch, behind a
  `GatewayTransport` interface (so it's testable without a real socket).
  Reconnects with backoff on a recoverable close or dropped connection,
  RESUMEs when the session allows it, falls back to a fresh IDENTIFY on
  INVALID_SESSION or when the session doesn't survive the gap.
- `GatewayShardManager` — owns one `GatewayConnection` per shard, merges
  their event/state streams, and paces IDENTIFYs across
  `session_start_limit.max_concurrency` buckets so shards don't all
  identify at once.

## Part of the fluxer_dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_dart_utils`](https://github.com/oppahansi/fluxer_dart_utils) | generic building blocks |
| [`fluxer_dart_core`](https://github.com/oppahansi/fluxer_dart_core) | domain models |
| [`fluxer_dart_rest`](https://github.com/oppahansi/fluxer_dart_rest) | REST client |
| [`fluxer_dart_gateway`](https://github.com/oppahansi/fluxer_dart_gateway) | *(this package)* WebSocket gateway client |
| [`fluxer_dart_voice`](https://github.com/oppahansi/fluxer_dart_voice) | voice support |
| [`fluxer_dart`](https://github.com/oppahansi/fluxer_dart) | main framework — the `Bot` facade |
| [`fluxer_dart_bot`](https://github.com/oppahansi/fluxer_dart_bot) | example bot |

## Installation

Not yet published to pub.dev. During development, depend on it via a path or
git dependency:

```yaml
dependencies:
  fluxer_dart_gateway:
    git:
      url: https://github.com/oppahansi/fluxer_dart_gateway.git
```

## License

MIT — see [LICENSE](LICENSE).
