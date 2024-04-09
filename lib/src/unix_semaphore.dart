part of '../runtime_native_semaphores.dart';

class _UnixSemaphore extends NativeSemaphore {
  late final Pointer<Char> _identifier;

  late final Pointer<sem_t> _semaphore;

  _UnixSemaphore({required String identifier}) : super._(identifier: identifier) {
    if (identifier.replaceFirst(('/'), '').length > UnixSemLimits.NAME_MAX_CHARACTERS)
      throw ArgumentError(
          'Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.');

    // TODO other checks on the identifier string
    _identifier = ('/${identifier.replaceFirst(('/'), '')}'.toNativeUtf8()).cast();

    _semaphore = sem_open(
        _identifier, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED);

    (_semaphore.address != UnixSemOpenMacros.SEM_FAILED.address) ||
        (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");
  }

  @override
  bool lock({bool blocking = true}) {
    return _locked = blocking ? sem_wait(_semaphore).isEven : sem_trywait(_semaphore).isEven;
  }

  @override
  bool unlock() {
    return !(_locked = !sem_post(_semaphore).isEven);
  }

  @override
  bool dispose() {
    bool __disposed = !locked || unlock();
    final int closed = sem_close(_semaphore);
    final int unlinked = sem_unlink(_identifier);

    __disposed =
        __disposed && (closed == 0 && closed.isEven) && (unlinked.isEven || (unlinked.isOdd && unlinked.isNegative));

    __disposed
        ? malloc.free(_identifier)
        : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore $_identifier.');
    return _disposed = __disposed;
  }

  @override
  String toString() => '_UnixSemaphore(_identifier: $_identifier)';
}
