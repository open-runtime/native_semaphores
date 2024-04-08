import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;

import 'package:ffi/ffi.dart' show Utf8Pointer, Utf8, malloc, StringUtf8Pointer;
import "package:runtime_native_semaphores/ffi/unix.dart"
    show MODE_T_PERMISSIONS, SemOpenError, SemOpenUnixMacros, errno, sem_close, sem_open, sem_t, sem_unlink;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

main() {
  Pointer<Char> name = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();
  Pointer<Char> name_2 = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();

  print(name.cast<Utf8>().toDartString());
  print(name_2.cast<Utf8>().toDartString());

  Pointer<sem_t> sem = sem_open(name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);
  Pointer<sem_t> sem_2 = sem_open(name_2, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

  print(sem);
  print(sem_2);

  // sleep(Duration(seconds: 5));

  try {
    (sem.address != SemOpenUnixMacros.SEM_FAILED.address) ||
        (throw "${SemOpenError.fromErrno(errno.value).toString()}");
  } catch (e) {
    print(e);
  }

  try {
    (sem_2.address != SemOpenUnixMacros.SEM_FAILED.address) ||
        (throw "${SemOpenError.fromErrno(errno.value).toString()}");
  } catch (e) {
    print(e);
  }

  print(sem_close(sem));
  print(sem_close(sem_2));

  print(sem_unlink(name));
  print(sem_unlink(name_2));

  malloc.free(name);
  malloc.free(name_2);
}
