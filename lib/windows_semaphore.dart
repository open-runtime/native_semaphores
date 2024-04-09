part of 'semaphore.dart';

class _WindowsSemaphore extends NativeSemaphore {
  bool locked = false;
  // bool acquired = false;
  late final LPCWSTR name;
  late final Pointer<NativeType> semaphore;

  _WindowsSemaphore({required String identifier}) : super._(identifier: identifier) {
    if (identifier.length > WindowsCreateSemaphoreWMacros.MAX_PATH)
      throw ArgumentError(
          'Identifier is too long. Must be less than or equal to ${WindowsCreateSemaphoreWMacros.MAX_PATH} characters.');

    identifier = identifier.replaceFirst('Global\\', '');
    identifier = identifier.replaceFirst('Local\\', '');

    // check if identifier has invalid characters
    if (identifier.contains(RegExp(r'[\\/:*?"<>|]'))) throw ArgumentError('Identifier contains invalid characters.');

    // Assume global for now
    name = ('Global\\${identifier}'.toNativeUtf16());

    int address = CreateSemaphoreW(
        WindowsCreateSemaphoreWMacros.NULL.address,
        WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
        WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
        name);

    semaphore = Pointer.fromAddress(address);

    semaphore.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
        (throw Exception("CreateSemaphoreW in secondary isolate should have succeeded, got ${semaphore.address}"));
  }

  @override
  bool lock({bool blocking = true}) {
    // TODO handle other cases i.e. WAIT_ABANDONED, WAIT_TIMEOUT, WAIT_FAILED etc.
    final int returnable = blocking
        ? WaitForSingleObject(semaphore.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED)
        : WaitForSingleObject(semaphore.address, WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO);
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) return locked = true;
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_ABANDONED) return false;
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT) return false;
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_FAILED) return false;
    return throw Exception('WaitForSingleObject returned an unexpected value: $returnable');
  }

  @override
  bool unlock() {
    return locked = !ReleaseSemaphore(semaphore.address, WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
            WindowsReleaseSemaphoreMacros.NULL)
        .isOdd;
  }

  @override
  bool dispose() {
    !locked || unlock();
    bool disposed = CloseHandle(semaphore.address).isOdd;
    disposed
        ? malloc.free(name)
        : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore name.');
    return disposed;
  }

  @override
  String toString() => '_WindowsSemaphore(name: $identifier)';
}
