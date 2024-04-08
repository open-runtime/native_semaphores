import 'dart:convert' show utf8;
import 'dart:ffi' show AbiSpecificIntegerPointer, Allocator, Char, DynamicLibrary, Pointer, Uint8, Uint8Pointer;
import 'dart:io' show Directory, Platform;
import 'dart:typed_data' show Uint8List;

import 'package:ffi/ffi.dart' show Utf16, Utf8Pointer, Utf8, malloc;
import 'package:path/path.dart' show join;
import "package:runtime_native_semaphores/ffi/unix.dart"
    show MODE_T_PERMISSIONS, SemOpenError, SemOpenUnixMacros, errno, sem_close, sem_open, sem_t, sem_unlink;
// import 'package:runtime_native_semaphores/generated_bindings_arm64.dart' show HelloWorld;
// import 'package:runtime_native_semaphores/generated_bindings.dart' show HelloWorld;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
// import 'package:runtime_native_semaphores/generated_bindings.dart' show HelloWorld;

/// Extension method for converting a [String] to a `Pointer<Utf16>`.
extension StringUtf16Pointer on String {
  Pointer<Char> toCString(Allocator alloc) {
    return toDebugNativeUtf8(allocator: alloc).cast();
  }

  /// Creates a zero-terminated [Utf16] code-unit array from this String.
  ///
  /// If this [String] contains NUL characters, converting it back to a string
  /// using [Utf16Pointer.toDartString] will truncate the result if a length is
  /// not passed.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  Pointer<Utf8> toDebugNativeUtf8({Allocator allocator = malloc}) {
    final units = utf8.encode(this);
    final Pointer<Uint8> result = allocator.allocate<Uint8>(units.length + 1);
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }

  void printCharAndRadix(Pointer<Char> pointer) {
    final Uint8List nativeString = pointer.cast<Uint8>().asTypedList(length);
    List<int> characters = [];
    List<String> radixValues = [];

    for (int i = 0; i < length; i++) {
      int charCode = nativeString[i];
      if (charCode == 0) break; // End of string
      characters.add(charCode);
      radixValues.add(charCode.toRadixString(16).padLeft(4, '0'));
    }

    print('Uint8: ${nativeString.toList()}');
    print('Characters: ${characters.join(" ")}');
    print('Radix 16: ${radixValues.join(" ")}');
  }

  void printCharacterCodesInHex(String input) {
    final StringBuffer hexCodes = StringBuffer();
    for (int unit in input.codeUnits) {
      hexCodes.write('0x${unit.toRadixString(16).padLeft(4, '0')} ');
    }
    print("Hex: $hexCodes");
  }
}

// // FFI signature of the hello_world C function
// typedef HelloWorldFunc = Void Function();
// // Dart type definition for calling the C foreign function
// typedef HelloWorld = void Function();

main() {
  // Open the dynamic library
  // var libraryPath = join(Directory.current.path, 'hello_library_arm64', 'libhello.so');
  //
  // if (Platform.isMacOS) {
  //   libraryPath = join(Directory.current.path, 'hello_library_arm64', 'libhello.dylib');
  // }
  //
  // if (Platform.isWindows) {
  //   libraryPath = join(Directory.current.path, 'hello_library_arm64', 'Debug', 'hello.dll');
  // }
  //
  // final dylib = DynamicLibrary.open(libraryPath);

  // // Look up the C function 'hello_world'
  // final HelloWorld hello = dylib.lookup<NativeFunction<HelloWorldFunc>>('hello_world').asFunction();
  // // Call the function
  //
  // hello();

  // print(HelloWorld(dylib).hello_world(native_name, 512, MODE_T_PERMISSIONS.RECOMMENDED, 1));
  //
  // print(HelloWorld(dylib).sem_open(native_name, 512));
  //  MODE_T_PERMISSIONS.RECOMMENDED, 1
  //
  // late Pointer<sem_t> semaphore;

  Pointer<Char> name = '/${safeIntId.getId()}-named-sem'.toCString(malloc);
  Pointer<Char> name_2 = '/${safeIntId.getId()}-named-sem'.toCString(malloc);
  // Pointer<Char> name = '/needing_to_test_here'.toCString(malloc);

  print(name.cast<Utf8>().toDartString());
  print(name_2.cast<Utf8>().toDartString());

  // print(sem_openPtr);
  // print(sem_open);

  // print(sem_openPtr_2);
  // print(sem_open_2);

  // Pointer<UnsignedInt> value = malloc.allocate<UnsignedInt>(1);

  // print(value.value);

  // int _sem = sem_open(name, 512);
  //
  // print(_sem);
  //
  // Pointer<sem_t> sem = Pointer.fromAddress(_sem);

  // Pointer<sem_t> sem = how_is_this_possible(name, 512, MODE_T_PERMISSIONS.RECOMMENDED, 1);

  Pointer<sem_t> sem = sem_open(name, 512, MODE_T_PERMISSIONS.RECOMMENDED, 1);
  // Pointer<sem_t> sem_2 = unverified_sem_open_2(name, 512, MODE_T_PERMISSIONS.RECOMMENDED);
  // Pointer<sem_t> sem = HelloWorld(DynamicLibrary.process()).sem_open(name, 512);
  // Pointer<sem_t> sem =
  //     HelloWorld(dylib).hello_world(name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);

  print(sem);
  // print(sem_2);

  // sleep(Duration(seconds: 5));

  try {
    (sem.address != SemOpenUnixMacros.SEM_FAILED.address) ||
        (throw "${SemOpenError.fromErrno(errno.value).toString()}");
  } catch (e) {
    print(e);
  }

  // try {
  //   (sem_2.address != SemOpenUnixMacros.SEM_FAILED.address) ||
  //       (throw "${SemOpenError.fromErrno(errno.value).toString()}");
  // } catch (e) {
  //   print(e);
  // }

  print(sem_close(sem));
  // print(sem_close(sem_2));

  print(sem_unlink(name));
  // print(sem_unlink(name_2));

  // Pointer<Char> name_2 = '/test_semaphore_three'.toCString(malloc);
  // Pointer<sem_t> sem_2 = sem_open_2(name_2, 512, MODE_T_PERMISSIONS.RECOMMENDED, 1);
  //
  // print(sem_2);
  //
  // try {
  //   (sem_2.address != SemOpenUnixMacros.SEM_FAILED.address) ||
  //       (throw "${SemOpenError.fromErrno(errno.value).toString()}");
  // } catch (e) {
  //   print(e);
  // }
  //
  // print(sem_close(sem_2));
  //
  // print(sem_unlink(name_2));

  // MODE_T_PERMISSIONS.RECOMMENDED, 1

  // print("about to call sem_open");

  // semaphore = sem_open('/test_semaphore_2'.toCString(malloc), 512, MODE_T_PERMISSIONS.RECOMMENDED, 1);

  // print("sem_open result: $semaphore");

  malloc.free(name);
  // malloc.free(value);
  // malloc.free(name_2);
}
