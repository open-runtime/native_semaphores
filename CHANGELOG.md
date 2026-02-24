# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-02-24

### Fixed
- Added shell-level org guard to triage.toml prompt to prevent upstream leakage, ensuring gh commands use --repo and only operate on open-runtime/pieces-app orgs
- Added missing 32-bit ARM Linux (Abi.linuxArm) mapping for mode_t to prevent AOT compilation failures on 32-bit ARM Linux targets (#20)

## [1.0.2] - 2026-02-24

### Changed
- Graduate to stable semver (bump to v1.0.1)
- Sync runtime_ci templates, dependency metadata, and bump runtime_ci_tooling to ^0.12.0

### Fixed
- Add Abi.linuxArm64 mapping for mode_t to fix AOT compilation on linux-arm64 (#17)
- Restore git ref for runtime_ci_tooling dependency
- Add top_level module and standardize autodoc output prefix

## [1.0.1]
- Graduate to stable semver (from `1.0.0-beta.7`)
- Fix: Add `Abi.linuxArm64` mapping for `mode_t` — resolves AOT compilation failure on linux-arm64 (PR #17)
- CI: Update to runtime_ci_tooling v0.11.3 with auto-format job and enhanced autodoc coverage
- Autodoc: Add comprehensive module documentation configuration

## [0.0.1]
- Initial release
- See test/semaphore_test.dart for unified usage examples
- See test/unix_named_semaphore_ffi_bindings_test.dart and test/windows_named_semaphore_ffi_bindings_test.dart for platform-specific usage examples

## [0.0.2]
- Reflect Platform Support in the README.md

## [0.0.3]
- Update README.md with more detailed usage examples, use cases, and background information/references
- Refine directory structure for more standardized dart code organization

## [0.0.4]
- Leverage the @Native decorator to re-implement `sem_open` 
- Extend `AbiSpecificInteger` with the `@AbiSpecificIntegerMapping` annotation to enable`mode_t` architecture specific type mappings i.e. UnsignedShort on x86_64 and UnsignedLong on arm64
- Guidance provided on this [dart-sdk issue](https://github.com/dart-lang/native/issues/1086) shout out to [@dcharkes](https://github.com/dcharkes) for the help!

## [0.0.5]
- Small changes to Pubspec.yaml to reflect platform support

## [1.0.0-beta.1]
- Initial release of the alpha version of the 1.0.0 release
- Made UnixNamedSemaphore and WindowsNamedSemaphore classes extendable to allow for custom implementations
- Refactored all classes to be extensible and now support reentrant behavior + counts of locks/unlocks within the same isolate/thread in addition to the initial cross process locking support.
- Updated unit tests to reflect recursive locking scenarios, and ensure proper implementation of SemaphoreIdentities and SemaphoreCounters
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## [1.0.0-beta.2]
- Small fix to pass `verbose` onto the `NativeSemaphore` constructor
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## [1.0.0-beta.3]
- Small fix on stray print statements here and there 
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## [1.0.0-beta.4]
- Small adjustments to README.md
- Small fix in CI/CD workflow to ensure proper testing across all platforms

## [1.0.0-beta.5]
- All tests are now passing on all platforms ?? (Windows, Linux, MacOS)
- ~~TODO~~DONE: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself
- TODO: Prepare for the 1.0.0 release

## [1.0.0-beta.6]
- Update GH Actions Steps i.e. @actions/checkout from v4.1.1 to use v4.1.4 and @dart-lang/setup-dart from v1.5.0 to use v1.6.4
- TODO: In code dartdoc comments for pub.dev API documentation
- TODO: GH Actions for Publishing to pub.dev

## [1.0.0-beta.7]
- Added cross process unit tests with dart AOT compiled binaries that all try to leverage the same named lock
- FIX: Fixed a bug where the SemaphoreIdentity wasn't getting the Semaphore's address assigned to it

[1.0.3]: https://github.com/open-runtime/native_semaphores/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/open-runtime/native_semaphores/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/open-runtime/native_semaphores/compare/v0.0.1...v1.0.1
[0.0.1]: https://github.com/open-runtime/native_semaphores/compare/v0.0.2...v0.0.1
[0.0.2]: https://github.com/open-runtime/native_semaphores/compare/v0.0.3...v0.0.2
[0.0.3]: https://github.com/open-runtime/native_semaphores/compare/v0.0.4...v0.0.3
[0.0.4]: https://github.com/open-runtime/native_semaphores/compare/v0.0.5...v0.0.4
[0.0.5]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.1...v0.0.5
[1.0.0-beta.1]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.2...v1.0.0-beta.1
[1.0.0-beta.2]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.3...v1.0.0-beta.2
[1.0.0-beta.3]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.4...v1.0.0-beta.3
[1.0.0-beta.4]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.5...v1.0.0-beta.4
[1.0.0-beta.5]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.6...v1.0.0-beta.5
[1.0.0-beta.6]: https://github.com/open-runtime/native_semaphores/compare/v1.0.0-beta.7...v1.0.0-beta.6
[1.0.0-beta.7]: https://github.com/open-runtime/native_semaphores/releases/tag/v1.0.0-beta.7
