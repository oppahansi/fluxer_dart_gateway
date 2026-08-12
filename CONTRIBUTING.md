# Contributing to fluxer_dart_gateway

Thanks for considering a contribution. fluxer_dart_gateway is one of seven
repositories in the `fluxer_dart` ecosystem — a Dart bot framework for
[Fluxer](https://fluxer.app):

| Package | Purpose |
|---|---|
| [`fluxer_dart_utils`](https://github.com/oppahansi/fluxer_dart_utils) | generic building blocks |
| [`fluxer_dart_core`](https://github.com/oppahansi/fluxer_dart_core) | domain models |
| [`fluxer_dart_rest`](https://github.com/oppahansi/fluxer_dart_rest) | REST client |
| [`fluxer_dart_gateway`](https://github.com/oppahansi/fluxer_dart_gateway) | WebSocket gateway client |
| [`fluxer_dart_voice`](https://github.com/oppahansi/fluxer_dart_voice) | voice support |
| [`fluxer_dart`](https://github.com/oppahansi/fluxer_dart) | main framework — the `Bot` facade |
| [`fluxer_dart_bot`](https://github.com/oppahansi/fluxer_dart_bot) | example bot |

Depends on `fluxer_dart_core` and `fluxer_dart_utils`; depended on by `fluxer_dart` and `fluxer_dart_voice`.

## Local development setup

The packages depend on each other via local `path:` entries in
`pubspec.yaml` during development, so clone the repos you need as
sibling directories (matching the names above) rather than in
isolation:

```sh
mkdir fluxer_dart_workspace && cd fluxer_dart_workspace
git clone https://github.com/oppahansi/fluxer_dart_utils.git
git clone https://github.com/oppahansi/fluxer_dart_core.git
git clone https://github.com/oppahansi/fluxer_dart_rest.git
git clone https://github.com/oppahansi/fluxer_dart_gateway.git
git clone https://github.com/oppahansi/fluxer_dart_voice.git
git clone https://github.com/oppahansi/fluxer_dart.git
git clone https://github.com/oppahansi/fluxer_dart_bot.git
```

Then, in fluxer_dart_gateway:

```sh
dart pub get
dart test
```

## Before opening a pull request

All three of these run in CI and must pass:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

Add or update tests for any behavior change — this ecosystem uses
`package:test` + `package:mocktail` (no codegen step) to mock the
REST/gateway boundary, so tests don't need live network access.

## Verifying changes

Fluxer's gateway wire protocol has **no OpenAPI spec at all** — the
only source of truth is `fluxerapp/fluxer`'s own source: the reference
client's TypeScript event handlers for dispatch payload shapes, and the
gateway server's own source for opcodes/close codes/sharding. Treat a
TypeScript type in the reference client as "what a well-behaved client
sends," not proof of what the server actually sends back — this
ecosystem has hit that exact gap in practice (a dispatch payload turned
out to carry less data than its reference-client type claimed, only
caught by testing against a live gateway connection).

If a PR adds or changes an event or connection-state behavior, mention
in the description where the shape was confirmed (a source file/line in
`fluxerapp/fluxer`, or better, a real payload captured from a live
connection), and ideally that it was tested against a real
(self-hosted) gateway, not just the mocked `GatewayTransport` unit
tests use.

## Commit messages

Commits follow [scoped commits](https://scopedcommits.com) —
`<scope>: <description>`, not Conventional Commits' `type(scope):`
format. Keep the description in imperative mood ("add", not "added").

## Code style

- `package:lints/recommended.yaml` — nothing stricter is enforced beyond
  what `dart analyze --fatal-infos` already catches.
- Default to no comments; when one is warranted, it should explain *why*
  something non-obvious is true, not restate what the code already says.
- Small, focused PRs are easier to review than large ones — if a change
  naturally splits into independent pieces, prefer separate PRs.

## Pull request process

1. Fork the repo and branch off `main`.
2. Make your change, with tests.
3. Make sure the three checks above pass locally.
4. Open a PR against `main` — the template will prompt for what's
   relevant.
5. CI runs the same three checks; a maintainer will review from there.

## Code of Conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting security issues

Please don't open a public issue for a security vulnerability — see
[SECURITY.md](SECURITY.md) instead.

## Questions

Open a [discussion or issue](https://github.com/oppahansi/fluxer_dart_gateway/issues) —
there's no separate chat/forum for this project.
