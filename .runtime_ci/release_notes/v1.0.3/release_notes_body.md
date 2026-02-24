# runtime_native_semaphores v1.0.3

> Bug fix release — 2026-02-24

## Bug Fixes

- **Add `Abi.linuxArm` mapping for `mode_t`** — Added the missing 32-bit ARM Linux ABI mapping for `mode_t` in `lib/src/ffi/unix.dart` to prevent AOT compilation failures on 32-bit ARM Linux targets. ([#20](https://github.com/open-runtime/runtime_native_semaphores/pull/20))
- **Enhance `triage.toml` security guards** — Added `--repo` and organization allowlist checks to the `.gemini/commands/triage.toml` prompt to prevent upstream leakage, ensuring `gh` commands only operate on `open-runtime` or `pieces-app` organizations in fork contexts.

## Upgrade

```bash
dart pub upgrade runtime_native_semaphores
```

## Issues Addressed

No linked issues for this release.
## Contributors

Thanks to everyone who contributed to this release:
- @tsavo-at-pieces
## Full Changelog

[v1.0.2...v1.0.3](https://github.com/open-runtime/runtime_native_semaphores/compare/v1.0.2...v1.0.3)
