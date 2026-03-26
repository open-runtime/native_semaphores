# runtime_native_semaphores v1.0.7

# Version Bump Rationale

- **Decision**: `patch`

The only change in this release is a maintenance update to remove `runtime_ci_tooling` from `dev_dependencies` in `pubspec.yaml`. Since the dependency is activated globally in CI, it does not need to be listed in `pubspec.yaml`, which avoids workspace resolution conflicts. 

Because this is a chore/maintenance task that only affects the build and CI configuration (not the public API or runtime behavior), a patch version bump is appropriate.

- **Key Changes**:
  - Removed `runtime_ci_tooling` from `dev_dependencies` in `pubspec.yaml`.

- **Breaking Changes**:
  - None.

- **New Features**:
  - None.

- **References**:
  - Pull Request #23
  - commit `chore: remove runtime_ci_tooling dev_dependency`



## Changelog

## [1.0.7] - 2026-03-26

### Changed
- Removed runtime_ci_tooling dev_dependency to prevent workspace resolution conflicts, deferring to global activation in CI instead (#23)

---
[Full Changelog](https://github.com/open-runtime/runtime_native_semaphores/compare/v1.0.6...v1.0.7)
