part of 'semaphore.dart';

// class _WindowsNamedLockNameType extends NamedLockNameType<String> {
//   _WindowsNamedLockNameType() : super._();
// }

class _WindowsSemaphore extends NativeSemaphore {
  // bool locked = false;
  // bool acquired = false;

  // Memory Allocation in Bytes
  // static const int _allocation = 8;

  // late final Pointer<HANDLE> handle = calloc.allocate(_WindowsNamedLock._allocation);

  // late final HANDLE mutex_handle;

  // static final _finalizer = Finalizer<Pointer<HANDLE>>((Pointer<HANDLE> ptr) {
  //   // TODO: Is this proper?
  //   calloc.free(ptr);
  // });

  _WindowsSemaphore({required String identifier}) : super._(identifier: identifier) {
    throw UnimplementedError();
  }

  @override
  bool acquire() {
    throw UnimplementedError();
  }

  @override
  bool lock() {
    throw UnimplementedError();
  }

  @override
  bool unlock() {
    throw UnimplementedError();
  }

  @override
  bool dispose() {
    throw UnimplementedError();
  }

  @override
  String toString() => '_WindowsSemaphore(name: $identifier)';
}
