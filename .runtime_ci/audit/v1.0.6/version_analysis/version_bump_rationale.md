#
# Version Bump Rationale

**Decision**: patch

**Reasoning**: 
The commits since the last release (v1.0.5) consist entirely of CI/CD updates, tooling configuration changes, automated documentation generation, and code formatting. There are no changes to the library's source code, logic, or public API. Because these are maintenance and infrastructure improvements that do not add new features or introduce breaking changes, a patch bump is appropriate according to semantic versioning rules.

**Key Changes**:
- Upgraded CI templates and regenerated workflows from `runtime_ci_tooling` (`v0.23.7` to `v0.23.10`).
- Enabled the `autodoc` feature in CI pipelines and updated generated documentation.
- Bumped `setup-dart` action to `v1.7.2` in workflows.
- Aligned Dart workspace resolution and updated development dependency versions in `pubspec.yaml`.
- Applied `dart format --line-length 120` across the codebase including formatting prompt scripts.
- Added Gemini autodoc safety policy.

**Breaking Changes**:
- None

**New Features**:
- None