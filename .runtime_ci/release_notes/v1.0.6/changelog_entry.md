## [1.0.6] - 2026-03-25

### Added
- Enabled autodoc feature flag, re-scanned modules, and added an autodoc job to the release pipeline
- Added file reading tools (read_file, glob, grep_search, list_directory) to Gemini settings and defined a strict markdown-only autodoc safety policy

### Changed
- Upgraded CI/CD templates and regenerated workflows from runtime_ci_tooling (v0.23.7 through v0.23.10), including a bump to setup-dart v1.7.2
- Configured the autodoc pipeline to use gemini-3-flash-preview for documentation reviews
- Aligned post-merge dependency versions across the workspace (#21)
- Aligned Dart workspace resolution and updated pub dependency constraints following cross-repo merges
- Auto-generated updated documentation and applied Dart line length formatting (120 characters) across the repository