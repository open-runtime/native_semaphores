part of 'semaphore.dart';

class _UnixSemaphore extends NativeSemaphore {
  bool locked = false;
  late final Pointer<Char> name;
  late final Pointer<sem_t> semaphore;

  _UnixSemaphore({required String identifier}) : super._(identifier: identifier) {
    if (identifier.replaceFirst(('/'), '').length > UnixSemLimits.NAME_MAX_CHARACTERS)
      throw ArgumentError(
          'Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.');
    // TODO other checks on the identifier string

    name = ('/${identifier.replaceFirst(('/'), '')}'.toNativeUtf8()).cast();

    semaphore =
        sem_open(name, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED);

    (semaphore.address != UnixSemOpenMacros.SEM_FAILED.address) ||
        (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");
  }

  @override
  bool lock({bool blocking = true}) {
    return locked = blocking ? sem_wait(semaphore).isEven : sem_trywait(semaphore).isEven;
  }

  @override
  bool unlock() {
    return locked = !sem_post(semaphore).isEven;
  }

  @override
  bool dispose() {
    !locked || unlock();
    final int closed = sem_close(semaphore);
    final int unlinked = sem_unlink(name);
    bool disposed = closed == unlinked && closed.isEven && unlinked.isEven;
    disposed
        ? malloc.free(name)
        : throw Exception('Failed to dispose semaphore and free memory allocated for semaphore name.');
    return disposed;
  }

  @override
  String toString() => '_WindowsSemaphore(name: $identifier)';
}
