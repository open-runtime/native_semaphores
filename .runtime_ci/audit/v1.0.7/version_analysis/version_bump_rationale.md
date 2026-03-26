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

