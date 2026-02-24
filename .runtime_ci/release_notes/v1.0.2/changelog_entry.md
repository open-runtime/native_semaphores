## [1.0.2] - 2026-02-24

### Changed
- Graduate to stable semver (bump to v1.0.1)
- Sync runtime_ci templates, dependency metadata, and bump runtime_ci_tooling to ^0.12.0

### Fixed
- Add Abi.linuxArm64 mapping for mode_t to fix AOT compilation on linux-arm64 (#17)
- Restore git ref for runtime_ci_tooling dependency
- Add top_level module and standardize autodoc output prefix