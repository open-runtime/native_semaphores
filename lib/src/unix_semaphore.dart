part of '../runtime_native_semaphores.dart';

class _UnixSemaphore extends NativeSemaphore {
  late final Pointer<Char> _identifier;

  late final Pointer<sem_t> _semaphore;

  _UnixSemaphore({required SemaphoreIdentity identity}) : super._(identity: identity) {
    if (identity.semaphore.replaceFirst(('/'), '').length > UnixSemLimits.NAME_MAX_CHARACTERS)
      throw ArgumentError(
          'Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.');

    // TODO other checks on the identifier string
    _identifier = ('/${identity.semaphore.replaceFirst(('/'), '')}'.toNativeUtf8()).cast();

    // Clean up unlinked semaphores here and unlinked persistence

    // implement persistence here i.e. attempt open vs open
    SemaphoreMetadata.persist(
            identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_INITIALIZATION) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_INITIALIZATION.name}.'));

    _semaphore = sem_open(
        _identifier, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED);

    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.INITIALIZED) ||
        (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.INITIALIZED.name}.'));

    (_semaphore.address != UnixSemOpenMacros.SEM_FAILED.address) ||
        (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");
  }

  @override
  bool lock({bool blocking = true}) {
    // TODO handle other cases i.e. EINTR, EAGAIN, EDEADLK etc.

    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_LOCK) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_LOCK.name}.'));

    _locked = SemaphoreMetadata.locks(identity: identity) > 0;

    // print(
    //     "Attempting Lock: Locked: $_locked ${SemaphoreMetadata.locks(identity: identity)} ${_semaphore.address} ${identity.toString()}");

    if (!_locked && SemaphoreMetadata.locks(identity: identity) == 0)
      _locked = blocking ? sem_wait(_semaphore).isEven : sem_trywait(_semaphore).isEven;

    if (_locked) {
      // Increment the semaphore count
      SemaphoreMetadata.increment(identity: identity);

      // print(
      //     "Completed Lock: Locked: $_locked ${SemaphoreMetadata.locks(identity: identity)} ${_semaphore.address} ${identity.toString()}");

      SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.LOCKED) ||
          (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.LOCKED.name}.'));
    }

    // implement persistence here i.e. attempt lock vs lock
    return _locked;
  }

  @override
  bool unlock() {
    // clean up lock persistence here
    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_UNLOCK) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_UNLOCK.name}.'));

    print(
        "Attempting Unlock: Locked: $_locked ${SemaphoreMetadata.locks(identity: identity)} ${_semaphore.address} ${identity.toString()}");

    final unlocked = SemaphoreMetadata.locks(identity: identity) == 1
        ? !(_locked = !sem_post(_semaphore).isEven)
        : SemaphoreMetadata.locks(identity: identity) < 1
            ? !(_locked = false)
            : false;

    // Decrement the semaphore count
    SemaphoreMetadata.decrement(identity: identity);

    print(
        "Completed Unlock: Locked: $_locked ${SemaphoreMetadata.locks(identity: identity)} ${_semaphore.address} ${identity.toString()}");

    // Probably persist the semaphore count here
    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.UNLOCKED) ||
        (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.UNLOCKED.name}.'));

    return unlocked;
  }

  // TODO document
  @override
  bool dispose() {
    if (SemaphoreMetadata.locks(identity: identity) > 0) return false;
    // if (SemaphoreMetadata.locks(identity: identity) > 0 && _locked) return false;

    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_DISPOSAL) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_DISPOSAL.name}.'));
    print(
        "Attempting Dispose: Locked: $locked ${SemaphoreMetadata.locks(identity: identity)} ${_semaphore.address} ${identity.toString()}");

    bool __disposed = !locked || unlock();

    // clean up unlock persistence here
    // implement persistence here i.e. attempt close vs close
    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_CLOSE) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_CLOSE.name}.'));

    final int closed = sem_close(_semaphore);
    final __closed = closed == 0 && closed.isEven;

    __closed && SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.CLOSED) ||
        (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.CLOSED.name}.'));

    // https://manpages.ubuntu.com/manpages/jammy/man7/sem_overview.7.html
    // TODO catch failed close and retry again in the future
    // clean up close persistence here

    // implement persistence here i.e. attempt unlink vs unlink
    SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_UNLINK) ||
        (throw Exception(
            'Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_UNLINK.name}.'));

    final int unlinked = sem_unlink(_identifier);
    final bool __unlinked = unlinked.isEven || (unlinked.isOdd && unlinked.isNegative);

    __unlinked && SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.UNLINKED) ||
        (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.UNLINKED.name}.'));

    __disposed = __disposed && __closed && __unlinked;

    __disposed
        ? malloc.free(_identifier)
        : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore $_identifier.');

    __disposed && SemaphoreMetadata.persist(identity: identity, status: NATIVE_SEMAPHORE_OPERATION_STATUS.DISPOSED) ||
        (throw Exception('Failed to persist semaphore status: ${NATIVE_SEMAPHORE_OPERATION_STATUS.DISPOSED.name}.'));

    return _disposed = __disposed;
  }

  @override
  String toString() => '_UnixSemaphore(_identifier: $_identifier)';
}
