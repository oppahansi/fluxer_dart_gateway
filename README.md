# fluxer_gateway

WebSocket gateway client for the [fluxer.dart](https://github.com/oppahansi/fluxer.dart) ecosystem.

Everything here was verified against Fluxer's own reference client source
(`fluxerapp/fluxer` on GitHub — `packages/constants/src/GatewayConstants.ts`,
`fluxer_app/.../GatewaySocket.ts`, `.../EventRouter.ts`), since Fluxer's
public gateway docs are still unwritten placeholders.

## Design

Deliberately structured around an **explicit connection state machine**
(`Disconnected → Connecting → Identifying|Resuming → Connected →
Reconnecting → Closed`) rather than the scattered nullable
fields/booleans Fluxer's own TS client uses to track connection state
(`shouldReconnectImmediately`, raw timeout IDs, etc.). Incoming events
decode into a sealed `GatewayEvent` hierarchy for exhaustive `switch`
handling instead of an untyped string-keyed handler map.

## What's here (v0.1 — M1 slice)

- `GatewayOpcode` / `GatewayCloseCode` — the full verified opcode (0–16)
  and close code (4000–4012) tables.
- `GatewayConnectionState` — the sealed state machine.
- `HeartbeatManager` — jittered heartbeat scheduling + ack tracking,
  matching Fluxer's own jitter formula (`base = max(1000, interval*0.8)`,
  `jitter = min(1500, interval*0.05)`).
- `GatewayEvent` — sealed dispatch event hierarchy covering `READY`,
  `RESUMED`, `MESSAGE_CREATE`, `GUILD_CREATE` for M1, with an
  `UnknownDispatchEvent` fallback for the ~50 other event names so
  messages in event types we haven't modeled yet don't crash the
  connection. Broadened in M3.
- `GatewayConnection` — the orchestrator: HELLO → IDENTIFY/RESUME →
  heartbeat loop → typed dispatch, behind a `GatewayTransport` interface
  (so it's testable without a real socket).

Sharding is structured into the design from day one (see the planning
docs in this ecosystem) but not yet activated — M1 runs a single shard.

## Part of the fluxer.dart ecosystem

| Package | Purpose |
|---|---|
| [`fluxer_utils`](https://github.com/oppahansi/fluxer_utils) | generic building blocks |
| [`fluxer_core`](https://github.com/oppahansi/fluxer_core) | domain models |
| [`fluxer_rest`](https://github.com/oppahansi/fluxer_rest) | REST client |
| [`fluxer_gateway`](https://github.com/oppahansi/fluxer_gateway) | *(this package)* WebSocket gateway client |
| [`fluxer.dart`](https://github.com/oppahansi/fluxer.dart) | main framework — the `Bot` facade |
| [`fluxer.dart-bot`](https://github.com/oppahansi/fluxer.dart-bot) | example bot |

## Installation

Not yet published to pub.dev. During development, depend on it via a path or
git dependency:

```yaml
dependencies:
  fluxer_gateway:
    git:
      url: https://github.com/oppahansi/fluxer_gateway.git
```

## License

MIT — see [LICENSE](LICENSE).
