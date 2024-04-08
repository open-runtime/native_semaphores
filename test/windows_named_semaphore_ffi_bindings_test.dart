@TestOn('windows')

import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart' show StringUtf16Pointer, StringUtf8Pointer, Utf16Pointer, Utf8, Utf8Pointer, malloc;
import "package:runtime_native_semaphores/ffi/unix.dart"
    show
        MODE_T_PERMISSIONS,
        UnixSemOpenError,
        UnixSemOpenMacros,
        errno,
        sem_close,
        sem_open,
        sem_post,
        sem_t,
        sem_trywait,
        sem_unlink,
        sem_wait;
import 'package:runtime_native_semaphores/ffi/windows.dart';
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart'
    show
        TestOn,
        contains,
        equals,
        everyElement,
        expect,
        group,
        isA,
        isNonZero,
        isTrue,
        isZero,
        setUp,
        tearDown,
        test,
        throwsA;
import 'package:win32/win32.dart' show GetLastError;
import 'package:windows_foundation/internal.dart' show getRestrictedErrorDescription;

void main() {
  group('Semaphore tests', () {
    test('Single Thread: Open, Close, Unlink Semaphore', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}-named-sem'.toNativeUtf16());

      int address = CreateSemaphoreW(WindowsCreateSemaphoreWMacros.NULL.address, 0, 1, name);
      final sem = Pointer.fromAddress(address);

      print("Semaphore address on windows $address");
      print("Semaphore on windows $sem");

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isNonZero); // 0 indicates failure

      final int closed = CloseHandle(sem.address);
      expect(closed, isNonZero); // 0 indicates failure

      malloc.free(name);
    });

    test('Single Thread: Throw Semaphore Name Error with Invalid Characters ', () {
      // Anything over 250 chars including the leading Global\ will be too long to fit into a the 260 int which is MAX_PATH
      LPCWSTR name = ('Global\\${'x<>:"/\\|?*' * WindowsCreateSemaphoreWMacros.MAX_PATH}'.toNativeUtf16());

      int address = CreateSemaphoreW(
          WindowsCreateSemaphoreWMacros.NULL.address,
          WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
          WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
          name);

      final sem = Pointer.fromAddress(address);

      expect(sem.address == WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      // We shouldn't be able to release the semaphore because it was never opened due to an invalid name
      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isZero); // 0 indicates failure

      // We shouldn't be able to close the semaphore because it was never opened due to an invalid name
      final int closed = CloseHandle(sem.address);
      expect(closed, isZero); // 0 indicates failure

      malloc.free(name);
    });

    test('Single Thread: Open, Lock, Unlock, and Close Semaphore', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}-named-sem'.toNativeUtf16());

      int address = CreateSemaphoreW(
          WindowsCreateSemaphoreWMacros.NULL.address,
          WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
          WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
          name);
      final sem = Pointer.fromAddress(address);

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);
      print("Locked: $locked");
      print(
          '${WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE}, ${WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0}, ${WindowsWaitForSingleObjectMacros.WAIT_ABANDONED}, ${WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT}');

      print("Error number: ${getRestrictedErrorDescription(GetLastError())}");
      print("Releasing Semaphore");

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isNonZero); // 0 indicates failure

      final int closed = CloseHandle(sem.address);
      expect(closed, isNonZero); // 0 indicates failure

      malloc.free(name);
    });

    test('Single Thread: Try to throw an error by calling `CloseHandle` twice.', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}-named-sem'.toNativeUtf16());

      int address = CreateSemaphoreW(WindowsCreateSemaphoreWMacros.NULL.address, 0, 1, name);
      final sem = Pointer.fromAddress(address);

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO);
      print("Locked: $locked");

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      print("Released: $released");
      expect(released, isNonZero); // 0 indicates failure

      final int closed = CloseHandle(sem.address);
      print("Closed: $closed");
      expect(closed, isNonZero); // 0 indicates failure

      final int closed_twice = CloseHandle(sem.address);
      print("Closed Twice: $closed_twice");
      print(getRestrictedErrorDescription(GetLastError()));
      expect(closed_twice, isZero); // 0 indicates failure

      malloc.free(name);
    });

    // group('Testing Cross-Isolate Named Semaphore', () {
    //   test('Two Isolates Accessing Same Named Semaphore, One Throws Immediately through O_EXCL Flag ', () async {
    //     Future<bool> spawn_primary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void primary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED,
    //             /*Passing in 0 to lock immediately */ 0);
    //
    //         sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
    //             (throw Exception(
    //                 "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));
    //
    //         sleep(Duration(seconds: 1));
    //
    //         // Unlock & expect 0
    //         final int unlocked = sem_post(sem);
    //         // expect(unlocked, equals(0));
    //         unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));
    //
    //         // Close & expect 0
    //         final int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));
    //
    //         // Signal completion
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     Future<bool> spawn_secondary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void secondary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);
    //
    //         final int error_number = errno.value;
    //
    //         sem.address == SemOpenUnixMacros.SEM_FAILED.address ||
    //             (throw Exception(
    //                 "sem_open in secondary isolate should have failed, got ${SemOpenError.fromErrno(error_number)}"));
    //
    //         error_number == SemOpenUnixMacros.EEXIST ||
    //             (throw Exception("Should have expected EEXIST, got something else $error_number"));
    //
    //         int closed = sem_close(sem);
    //         (closed.isNegative && closed.isOdd) ||
    //             (throw Exception("sem_closed in secondary isolate should have expected -1, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     String name = '/${safeIntId.getId()}-named-sem';
    //
    //     // Spawn the first helper isolate
    //     final result_one = spawn_primary_isolate(name);
    //
    //     sleep(Duration(milliseconds: 250));
    //
    //     final result_two = spawn_secondary_isolate(name);
    //
    //     // Wait for both isolates to complete their work
    //     final outcomes = await Future.wait([result_one, result_two]);
    //
    //     Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //     final int unlinked = sem_unlink(_name);
    //
    //     expect(unlinked, equals(0));
    //     expect(outcomes, everyElement(equals(true)));
    //   });
    //
    //   test(
    //       'Two Isolates Accessing Same Named Semaphore with O_CREAT flag, one locks for a 3 second Duration, the other waits to lock and then unlocks',
    //       () async {
    //     Future<bool> spawn_primary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void primary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED,
    //             /*Passing in 0 to lock immediately */ 0);
    //
    //         sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
    //             (throw Exception(
    //                 "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));
    //
    //         // Waiting in primary isolate for 3 seconds.
    //         sleep(Duration(seconds: 3));
    //
    //         // Unlock
    //         final int unlocked = sem_post(sem);
    //         // expect(unlocked, equals(0));
    //         unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));
    //
    //         // Close & expect 0
    //         final int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     Future<bool> spawn_secondary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void secondary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);
    //
    //         int waited = sem_wait(sem);
    //         waited.isEven || (throw Exception("sem_wait in secondary isolate should have expected 0, got $waited"));
    //
    //         int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_closed in secondary isolate should have expected 0, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     String name = '/${safeIntId.getId()}-named-sem';
    //
    //     // Spawn the first helper isolate
    //     final result_one = spawn_primary_isolate(name);
    //     sleep(Duration(milliseconds: 250));
    //     final result_two = spawn_secondary_isolate(name);
    //
    //     // Wait for both isolates to complete their work
    //     final outcomes = await Future.wait([result_one, result_two]);
    //
    //     Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //     final int unlinked = sem_unlink(_name);
    //
    //     expect(unlinked, equals(0));
    //     expect(outcomes, everyElement(equals(true)));
    //   });
    //
    //   test(
    //       'Two Isolates Accessing Same Named Semaphore with O_CREAT flag, one locks for a 3 second Duration, the other try_wait(s), fails, try_waits and throws an error',
    //       () async {
    //     Future<bool> spawn_primary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void primary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);
    //
    //         sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
    //             (throw Exception(
    //                 "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));
    //
    //         final int locked = sem_wait(sem);
    //         locked.isEven || (throw Exception("sem_wait in primary isolate should have expected 0, got $locked"));
    //
    //         // Waiting in primary isolate for 3 seconds.
    //         sleep(Duration(seconds: 1));
    //
    //         // Unlock
    //         final int unlocked = sem_post(sem);
    //         unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));
    //
    //         // Close
    //         final int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_close in primary isolate should have expected 0, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     Future<bool> spawn_secondary_isolate(String name) async {
    //       // The entry point for the isolate
    //       void secondary_isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //         Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);
    //
    //         int waited = sem_trywait(sem);
    //
    //         (waited.isOdd && waited.isNegative) ||
    //             (throw Exception("sem_wait in secondary isolate should have expected -1, got $waited"));
    //
    //         // await 2 seconds and try again
    //         sleep(Duration(seconds: 2));
    //         int successfully_trywaited = sem_trywait(sem);
    //         successfully_trywaited.isEven ||
    //             (throw Exception(
    //                 "second call to sem_trywait in secondary isolate should have expected 0, got $successfully_trywaited"));
    //
    //         int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_closed in secondary isolate should have expected 0, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     String name = '/${safeIntId.getId()}-named-sem';
    //
    //     // Spawn the first helper isolate
    //     final result_one = spawn_primary_isolate(name);
    //     sleep(Duration(milliseconds: 250));
    //     final result_two = spawn_secondary_isolate(name);
    //
    //     // Wait for both isolates to complete their work
    //     final outcomes = await Future.wait([result_one, result_two]);
    //
    //     Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //     final int unlinked = sem_unlink(_name);
    //
    //     expect(unlinked, equals(0));
    //     expect(outcomes, everyElement(equals(true)));
    //   });
    //
    //   test(
    //       'Several Isolates Accessing Same Named Semaphore, all with O_CREAT flag, waiting random durations and then unlocking.',
    //       () async {
    //     Future<bool> spawn_isolate(String name, int sem_open_value, int id) async {
    //       // The entry point for the isolate
    //       void isolate_entrypoint(SendPort sender) {
    //         Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //         Pointer<sem_t> sem =
    //             sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, sem_open_value);
    //
    //         sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
    //             (throw Exception(
    //                 "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));
    //
    //         int waited = sem_wait(sem);
    //
    //         waited.isEven || (throw Exception("sem_wait in isolate $id should have expected 0, got $waited"));
    //
    //         // Waiting in primary isolate for 3 seconds.
    //         sleep(Duration(milliseconds: Random().nextInt(1000)));
    //
    //         // Unlock
    //         final int unlocked = sem_post(sem);
    //         unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));
    //
    //         // Close & expect 0
    //         final int closed = sem_close(sem);
    //         closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));
    //
    //         sender.send(true);
    //         malloc.free(_name);
    //       }
    //
    //       // Create a receive port to get messages from the isolate
    //       final ReceivePort receiver = ReceivePort();
    //
    //       // Spawn the isolate
    //       await Isolate.spawn(isolate_entrypoint, receiver.sendPort);
    //
    //       // Wait for the isolate to send its message
    //       return await receiver.first;
    //     }
    //
    //     String name = '/${safeIntId.getId()}-named-sem';
    //
    //     int sem_open_value = 1;
    //     // Spawn the first helper isolate
    //     final result_one = spawn_isolate(name, sem_open_value, 1);
    //     final result_two = spawn_isolate(name, sem_open_value, 2);
    //     final result_three = spawn_isolate(name, sem_open_value, 3);
    //     final result_four = spawn_isolate(name, sem_open_value, 4);
    //
    //     // Wait for both isolates to complete their work
    //     final outcomes = await Future.wait([result_one, result_two, result_three, result_four]);
    //
    //     Pointer<Char> _name = (name.toNativeUtf8()).cast();
    //     final int unlinked = sem_unlink(_name);
    //
    //     expect(unlinked, equals(0));
    //     expect(outcomes, everyElement(equals(true)));
    //   });
    // });
  });
}
