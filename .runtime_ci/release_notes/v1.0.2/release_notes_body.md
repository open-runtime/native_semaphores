# runtime_native_semaphores v1.0.2

> Bug fix release — 2026-02-24

## Bug Fixes

- **Linux ARM64 AOT Compilation** — Fixed an AOT (`dart compile exe`) compilation failure on linux-arm64 systems by mapping `Abi.linuxArm64` for `mode_t` in the FFI bindings. ([#17](https://github.com/open-runtime/runtime_native_semaphores/pull/17))
- **Documentation Generation** — Standardized the autodoc output prefix to `docs/` and introduced the `top_level` module to ensure API references generate correctly.
- **CI Dependency Fixes** — Restored broken git references for the internal `runtime_ci_tooling` dependency to resolve workflow failures.

## Upgrade

```bash
dart pub upgrade runtime_native_semaphores
```

## Contributors

Thanks to everyone who contributed to this release:
- @al-the-bear
- @tsavo-at-pieces
## Issues Addressed

No linked issues for this release.
## Full Changelog

[v1.0.0-beta.7...v1.0.2](https://github.com/open-runtime/runtime_native_semaphores/compare/v1.0.0-beta.7...v1.0.2)
