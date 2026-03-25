# runtime_native_semaphores v1.0.6

> Maintenance release — 2026-03-25

## Maintenance & Tooling Updates

This patch release focuses entirely on continuous integration, automated documentation, and tooling enhancements. There are no changes to the library's underlying source code, logic, or public API.

- **Automated Documentation** — Enabled the new `autodoc` pipeline to auto-generate comprehensive API references, quickstarts, and examples. Configured the pipeline to use `gemini-3-flash-preview` for documentation generation and review.
- **CI/CD Upgrades** — Upgraded CI templates and regenerated GitHub Actions workflows from `runtime_ci_tooling` (v0.23.7 through v0.23.10), including bumping the `setup-dart` action to `v1.7.2`.
- **Dependency Alignment** — Aligned post-merge workspace dependency versions and updated `pubspec.yaml` dependency constraints to keep the repository in sync with workspace resolution expectations. ([#21](https://github.com/open-runtime/runtime_native_semaphores/pull/21))
- **Code Formatting** — Applied uniform 120-character Dart line length formatting across the codebase, including formatting of prompt scripts.

## Issues Addressed

No linked issues for this release.
## Install / Upgrade

**Existing consumers:**
```bash
dart pub upgrade runtime_native_semaphores
```

**New consumers — add to your `pubspec.yaml`:**
```yaml
dependencies:
  runtime_native_semaphores:
    git:
      url: git@github.com:open-runtime/runtime_native_semaphores.git
      tag_pattern: v{{version}}
```

Then run `dart pub get` to install.

> View on [GitHub](https://github.com/open-runtime/runtime_native_semaphores/releases/tag/v1.0.6)

## Full Changelog

[v1.0.5...v1.0.6](https://github.com/open-runtime/runtime_native_semaphores/compare/v1.0.5...v1.0.6)

## Contributors

(auto-generated from verified commit data)
