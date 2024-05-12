## 0.0.1
- Initial release
- See test/semaphore_test.dart for unified usage examples
- See test/unix_named_semaphore_ffi_bindings_test.dart and test/windows_named_semaphore_ffi_bindings_test.dart for platform-specific usage examples

## 0.0.2
- Reflect Platform Support in the README.md

## 0.0.3
- Update README.md with more detailed usage examples, use cases, and background information/references
- Refine directory structure for more standardized dart code organization

## 0.0.4
- Leverage the @Native decorator to re-implement `sem_open` 
- Extend `AbiSpecificInteger` with the `@AbiSpecificIntegerMapping` annotation to enable`mode_t` architecture specific type mappings i.e. UnsignedShort on x86_64 and UnsignedLong on arm64
- Guidance provided on this [dart-sdk issue](https://github.com/dart-lang/native/issues/1086) shout out to [@dcharkes](https://github.com/dcharkes) for the help!

## 0.0.5
- Small changes to Pubspec.yaml to reflect platform support

## 1.0.0-beta.1
- Initial release of the alpha version of the 1.0.0 release
- Made UnixNamedSemaphore and WindowsNamedSemaphore classes extendable to allow for custom implementations
- Refactored all classes to be extensible and now support reentrant behavior + counts of locks/unlocks within the same isolate/thread in addition to the initial cross process locking support.
- Updated unit tests to reflect recursive locking scenarios, and ensure proper implementation of SemaphoreIdentities and SemaphoreCounters
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## 1.0.0-beta.2
- Small fix to pass `verbose` onto the `NativeSemaphore` constructor
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## 1.0.0-beta.3
- Small fix on stray print statements here and there 
- TODO: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself

## 1.0.0-beta.4
- Small adjustments to README.md
- Small fix in CI/CD workflow to ensure proper testing across all platforms

## 1.0.0-beta.5
- All tests are now passing on all platforms ?? (Windows, Linux, MacOS)
- ~~TODO~~DONE: @tsavo-at-pieces Re-Implement WindowsNamedSemaphore to support reentrant locking and intra-isolate counts
- TODO: @tsavo-at-pieces Implement a clean-up mechanism for stray locks across the OS
- TODO: @tsavo-at-pieces Implement a way to track lock requests/blocked executions across processes due to current process having yet to unlock itself
- TODO: Prepare for the 1.0.0 release

## 1.0.0-beta.6
- Update GH Actions Steps i.e. @actions/checkout from v4.1.1 to use v4.1.4 and @dart-lang/setup-dart from v1.5.0 to use v1.6.4
- TODO: In code dartdoc comments for pub.dev API documentation
- TODO: GH Actions for Publishing to pub.dev

