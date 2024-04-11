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