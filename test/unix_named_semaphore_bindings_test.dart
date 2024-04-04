import 'dart:convert';
import 'dart:ffi'
    show AbiSpecificIntegerPointer, Allocator, Char, Int, Pointer, Uint16, Uint16Pointer, Uint8, Uint8Pointer;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' show StringUtf16Pointer, StringUtf8Pointer, Utf16, Utf8, malloc;
import 'package:runtime_native_semaphores/ffi/unix.dart'
    show MODE_T_PERMISSIONS, SemOpenError, SemOpenUnixMacros, errno, sem_close, sem_open, sem_t, sem_unlink, sem_wait;
import 'package:test/test.dart' show equals, expect, group, isNonZero, isTrue, setUp, tearDown, test;

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

void main() {
  group('Semaphore tests', () {
    String name = 'test_semaphore';
    Pointer<Char> native_name = name.toCString(malloc);
    late Pointer<sem_t> semaphore;

    name.printCharacterCodesInHex(name);
    name.printCharAndRadix(native_name);

    setUp(() {});

    tearDown(() {
      // Clean up any resources
      // if (semaphore.address != 0) {
      //   sem_close(semaphore);
      //   sem_unlink('/test_semaphore'.toNativeUtf16());
      malloc.free(native_name);
      // }
    });

    test('Successfully create and unlink a semaphore', () {
      semaphore = sem_open(native_name, 512);

      print("sem_open result: $semaphore");

      (semaphore.address != SemOpenUnixMacros.SEM_FAILED.address) ||
          (throw "${SemOpenError.fromErrno(errno.value).toString()}");

      expect(semaphore.address != 0, isTrue);

      // int result = sem_unlink(native_name);

      // print("sem_unlink result: $result");
      //
      // expect(result, equals(0)); // 0 indicates success
    });

    // test('Successfully lock and unlock a semaphore', () {
    // semaphore = sem_open(Utf16.toUtf16('/test_semaphore'), 0o666, 0, 1);
    // expect(semaphore.address != 0, isTrue);
    //
    // var waitResult = sem_wait(semaphore);
    // expect(waitResult, equals(0)); // 0 indicates success
    //
    // var postResult = sem_post(semaphore);
    // expect(postResult, equals(0)); // 0 indicates success
    // });

    // test('Access errno after unsuccessful semaphore operation', () {
    // semaphore = sem_open(Utf16.toUtf16('/nonexistent_semaphore'), 0, 0, 0); // Intentionally wrong
    // expect(semaphore.address, equals(0)); // Indicates failure
    //
    // Pointer<Int> errnoPtr = errno();
    // int currentErrno = errnoPtr.value;
    // expect(currentErrno, isNonZero); // Errno should be non-zero after failure
    // });
  });
}
