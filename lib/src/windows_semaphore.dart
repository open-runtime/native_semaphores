part of '../runtime_native_semaphores.dart';

class _WindowsSemaphore extends NativeSemaphore {
  late final LPCWSTR _identifier;

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
    _identifier = ('Global\\${identifier}'.toNativeUtf16());

    int address = CreateSemaphoreW(
        WindowsCreateSemaphoreWMacros.NULL.address,
        WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
        WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
        _identifier);

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
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) return _locked = true;
    // TODO potentially get the status of locked before setting it to false here
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_ABANDONED) return _locked = false;
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT) return _locked = false;
    if (returnable == WindowsWaitForSingleObjectMacros.WAIT_FAILED) return _locked = false;
    return throw Exception('WaitForSingleObject returned an unexpected value: $returnable');
  }

  @override
  bool unlock() {
    return !(_locked = !ReleaseSemaphore(semaphore.address, WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
            WindowsReleaseSemaphoreMacros.NULL)
        .isOdd);
  }

  @override
  bool dispose() {
    bool __disposed = (!locked || unlock()) && CloseHandle(semaphore.address).isOdd;

    __disposed
        ? malloc.free(_identifier)
        : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore $_identifier.');

    return _disposed = __disposed;
  }

  @override
  String toString() => '_WindowsSemaphore(_identifier: $_identifier)';
}
