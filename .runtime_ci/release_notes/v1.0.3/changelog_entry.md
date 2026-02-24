## [1.0.3] - 2026-02-24

### Fixed
- Added shell-level org guard to triage.toml prompt to prevent upstream leakage, ensuring gh commands use --repo and only operate on open-runtime/pieces-app orgs
- Added missing 32-bit ARM Linux (Abi.linuxArm) mapping for mode_t to prevent AOT compilation failures on 32-bit ARM Linux targets (#20)