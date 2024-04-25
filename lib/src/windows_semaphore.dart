part of runtime_native_semaphores.semaphore;

class _WindowsSemaphore<
    /*  Identity */
    I extends SemaphoreIdentity,
    /* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
    /* Semaphore Count */
    CT extends SemaphoreCount,
    /* Semaphore Counts */
    CTS extends SemaphoreCounts<CT>,
    /* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CT, CTS>,
    /* Semaphore Counter */
    CTRS extends SemaphoreCounters<I, CT, CTS, CTR>
    /* formatting guard comment */
    > extends NativeSemaphore<I, IS, CT, CTS, CTR, CTRS> {
  bool _locked = false;
  bool _disposed = false;
  bool locked = false;

  late final LPCWSTR _identifier;

  late final Pointer<NativeType> semaphore;

  _WindowsSemaphore({required String name, required CTR counter}) : super._(name: name, counter: counter) {
    // if (identity.semaphore.length > WindowsCreateSemaphoreWMacros.MAX_PATH)
    //   throw ArgumentError(
    //       'Identifier is too long. Must be less than or equal to ${WindowsCreateSemaphoreWMacros.MAX_PATH} characters.');
    //
    // // Assume global for now
    // _identifier = ('Global\\${identity.semaphore}'.toNativeUtf16());
    //
    // // Clean up unlinked semaphores here and unlinked persistence
    //
    // // implement persistence here i.e. attempt open vs open
    //
    // int address = CreateSemaphoreW(
    //     WindowsCreateSemaphoreWMacros.NULL.address,
    //     WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
    //     WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
    //     _identifier);
    //
    // semaphore = Pointer.fromAddress(address);
    //
    // semaphore.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
    //     (throw Exception("CreateSemaphoreW in secondary isolate should have succeeded, got ${semaphore.address}"));
  }

  @override
  bool lock({bool blocking = true}) {
    return false;
    // // TODO handle other cases i.e. WAIT_ABANDONED, WAIT_TIMEOUT, WAIT_FAILED etc.
    // final int returnable = blocking
    //     ? WaitForSingleObject(semaphore.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED)
    //     : WaitForSingleObject(semaphore.address, WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO);
    // if (returnable == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) return _locked = true;
    // // TODO potentially get the status of locked before setting it to false here
    // if (returnable == WindowsWaitForSingleObjectMacros.WAIT_ABANDONED) return _locked = false;
    // if (returnable == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT) return _locked = false;
    // if (returnable == WindowsWaitForSingleObjectMacros.WAIT_FAILED) return _locked = false;
    // // implement persistence here i.e. attempt lock vs lock
    // return throw Exception('WaitForSingleObject returned an unexpected value: $returnable');
  }

  @override
  bool unlock() {
    return false;
    // final unlocked = !(_locked = !ReleaseSemaphore(semaphore.address,
    //         WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED, WindowsReleaseSemaphoreMacros.NULL)
    //     .isOdd);
    // // implement persistence here i.e. attempt unlock vs unlock
    // return unlocked;
  }

  @override
  bool dispose() {
    return false;
    // bool __unlocked = !locked || unlock();
    // // clean up unlock persistence here
    //
    // // implement persistence here i.e. attempt close vs close
    // bool __closed = CloseHandle(semaphore.address).isOdd;
    // // clean up close persistence here
    //
    // bool __disposed = __unlocked && __closed;
    //
    // __disposed
    //     ? malloc.free(_identifier)
    //     : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore $_identifier.');
    //
    // return _disposed = __disposed;
  }

  @override
  String toString() => '_WindowsSemaphore(_identifier: $_identifier)';
}
