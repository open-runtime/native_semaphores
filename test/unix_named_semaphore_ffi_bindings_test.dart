import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart' show Utf8Pointer, Utf8, malloc, StringUtf8Pointer;
import "package:runtime_native_semaphores/ffi/unix.dart"
    show
        MODE_T_PERMISSIONS,
        SemOpenError,
        SemOpenUnixMacros,
        errno,
        sem_close,
        sem_open,
        sem_post,
        sem_t,
        sem_trywait,
        sem_unlink,
        sem_wait;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart'
    show contains, equals, everyElement, expect, group, isA, isNonZero, isTrue, setUp, tearDown, test, throwsA;

void main() {
  group('Semaphore tests', () {
    tearDown(() {
      // Clean up any resources
      // if (semaphore.address != 0) {
      //   sem_close(semaphore);
      //   sem_unlink('/test_semaphore'.toNativeUtf16());
      // malloc.free(native_name);
      // }
    });

    test('Single Thread: Open, Close, Unlink Semaphore', () {
      Pointer<Char> name = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();

      Pointer<sem_t> sem = sem_open(name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      // expect sem_open to not be SemOpenUnixMacros.SEM_FAILED
      expect(sem.address != SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      try {
        (sem.address != SemOpenUnixMacros.SEM_FAILED.address) ||
            (throw "${SemOpenError.fromErrno(errno.value).toString()}");
      } catch (e) {
        print(e);
      }

      final int closed = sem_close(sem);
      expect(closed, equals(0)); // 0 indicates success

      final int unlinked = sem_unlink(name);
      expect(unlinked, equals(0)); // 0 indicates success

      malloc.free(name);
    });

    test('Single Thread: Throw Semaphore Name Too Long ', () {
      // Anything over 30 chars including the leading slash will be too long to fit into a 255 int which is NAME_MAX
      Pointer<Char> name = ('/${'x' * 30}'.toNativeUtf8()).cast();

      Pointer<sem_t> sem = sem_open(name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem.address == SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      final int error_number = errno.value;

      expect(error_number, equals(SemOpenUnixMacros.ENAMETOOLONG));

      expect(
          () => throw SemOpenError.fromErrno(error_number),
          throwsA(isA<SemOpenError>()
              .having((e) => e.message, 'message', contains(SemOpenError.fromErrno(error_number).message))));

      malloc.free(name);
    });

    test('Single Thread: Throw Semaphore Already Exists with O_EXCL Flag', () {
      // Anything over 30 chars including the leading slash will be too long to fit into a 255 int which is NAME_MAX
      Pointer<Char> name = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();

      Pointer<sem_t> sem_one = sem_open(name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem_one.address != SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      Pointer<sem_t> sem_two = sem_open(/*Passing in same name */ name,
          /*Passing in O_EXCL Flag */ SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem_two.address == SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      final int error_number = errno.value;

      expect(error_number, equals(SemOpenUnixMacros.EEXIST));

      expect(
          () => throw SemOpenError.fromErrno(error_number),
          throwsA(isA<SemOpenError>()
              .having((e) => e.message, 'message', contains(SemOpenError.fromErrno(error_number).message))));

      // Only need to close sem_one here because sem_two was never opened
      final int closed = sem_close(sem_one);
      expect(closed, equals(0)); // 0 indicates success

      final int unlinked = sem_unlink(name);
      expect(unlinked, equals(0)); // 0 indicates success

      malloc.free(name);
    });

    test('Single Thread: Opens Existing Semaphore with the same `name` and `O_CREATE` Flag', () {
      // Anything over 30 chars including the leading slash will be too long to fit into a 255 int which is NAME_MAX
      Pointer<Char> name = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();

      /// First [sem_open] Call: When you call [sem_open] for the first time with a given name and the [O_CREAT] flag,
      /// the system checks if a semaphore with that name already exists. If it doesn't, the system creates a new named
      /// semaphore. This semaphore is identified by its [name], not by its memory address in your process.
      /// The function returns a semaphore descriptor (a pointer) that refers to the semaphore object.
      Pointer<sem_t> sem_one = sem_open(name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem_one.address != SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      // Second [sem_open] Call: When you call [sem_open] again with the same name and the [O_CREAT] flag, the system
      // finds that a semaphore with that name already exists. Since you're not using the [O_EXCL] flag
      // (which would cause the call to fail if the semaphore already exists), the system simply opens
      // the existing semaphore. However, the returned semaphore descriptor (pointer) from this second call may be
      // different from the first call. This is because the descriptor is just a handle or a reference to the
      // semaphore object in the kernel, and each call to [sem_open] can return a different handle for
      // the same underlying semaphore object.
      Pointer<sem_t> sem_two = sem_open(/*Passing in same name */ name,
          /*Passing in O_CREAT Flag */ SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem_two.address != SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      // Note that the error number here could be incorrectly reported as it is persisted still from other tests

      final int closed_one = sem_close(sem_one);
      expect(closed_one, equals(0)); // 0 indicates success

      final int closed_two = sem_close(sem_two);
      expect(closed_two, equals(0)); // 0 indicates success

      final int unlinked_one = sem_unlink(name);
      expect(unlinked_one, equals(0)); // 0 indicates success

      final int unlinked_two = sem_unlink(name);
      expect(unlinked_two, equals(-1)); // -1 indicates success because the semaphore was already unlinked

      malloc.free(name);
    });

    test('Single Thread: Open, Lock (Wait), Unlock (Post), Lock (TryWait), Unlock (Post), Close, Unlink Semaphore ',
        () {
      // Anything over 30 chars including the leading slash will be too long to fit into a 255 int which is NAME_MAX
      Pointer<Char> name = ('/${safeIntId.getId()}-named-sem'.toNativeUtf8()).cast();

      Pointer<sem_t> sem = sem_open(name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

      expect(sem.address != SemOpenUnixMacros.SEM_FAILED.address, isTrue);

      int locked = sem_wait(sem);
      expect(locked, equals(0));

      int unlocked = sem_post(sem);
      expect(unlocked, equals(0));

      int locked_try_wait = sem_trywait(sem);
      expect(locked_try_wait, equals(0));

      int unlocked_after_try_wait = sem_post(sem);
      expect(unlocked_after_try_wait, equals(0));

      final int closed = sem_close(sem);
      expect(closed, equals(0)); // 0 indicates success

      final int unlinked = sem_unlink(name);
      expect(unlinked, equals(0));

      malloc.free(name);
    });
  });

  group('Testing Cross-Isolate Named Semaphore', () {
    test('Two Isolates Accessing Same Named Semaphore, One Throws Immediately through O_EXCL Flag ', () async {
      Future<bool> spawn_primary_isolate(String name) async {
        // The entry point for the isolate
        void primary_isolate_entrypoint(SendPort sender) {
          Pointer<Char> _name = (name.toNativeUtf8()).cast();

          Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED,
              /*Passing in 0 to lock immediately */ 0);

          sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
              (throw Exception(
                  "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));

          sleep(Duration(seconds: 1));

          // Unlock & expect 0
          final int unlocked = sem_post(sem);
          // expect(unlocked, equals(0));
          unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));

          // Close & expect 0
          final int closed = sem_close(sem);
          closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));

          // Signal completion
          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      Future<bool> spawn_secondary_isolate(String name) async {
        // The entry point for the isolate
        void secondary_isolate_entrypoint(SendPort sender) {
          Pointer<Char> _name = (name.toNativeUtf8()).cast();
          Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_EXCL, MODE_T_PERMISSIONS.RECOMMENDED, 1);

          final int error_number = errno.value;

          sem.address == SemOpenUnixMacros.SEM_FAILED.address ||
              (throw Exception(
                  "sem_open in secondary isolate should have failed, got ${SemOpenError.fromErrno(error_number)}"));

          error_number == SemOpenUnixMacros.EEXIST ||
              (throw Exception("Should have expected EEXIST, got something else $error_number"));

          int closed = sem_close(sem);
          (closed.isNegative && closed.isOdd) ||
              (throw Exception("sem_closed in secondary isolate should have expected -1, got $closed"));

          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '/${safeIntId.getId()}-named-sem';

      // Spawn the first helper isolate
      final result_one = spawn_primary_isolate(name);

      sleep(Duration(milliseconds: 250));

      final result_two = spawn_secondary_isolate(name);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two]);

      Pointer<Char> _name = (name.toNativeUtf8()).cast();
      final int unlinked = sem_unlink(_name);

      expect(unlinked, equals(0));
      expect(outcomes, everyElement(equals(true)));
    });

    test(
        'Two Isolates Accessing Same Named Semaphore with O_CREAT flag, one locks for a 3 second Duration, the other waits to lock and then unlocks',
        () async {
      Future<bool> spawn_primary_isolate(String name) async {
        // The entry point for the isolate
        void primary_isolate_entrypoint(SendPort sender) {
          Pointer<Char> _name = (name.toNativeUtf8()).cast();

          Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED,
              /*Passing in 0 to lock immediately */ 0);

          sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
              (throw Exception(
                  "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));

          // Waiting in primary isolate for 3 seconds.
          sleep(Duration(seconds: 3));

          // Unlock
          final int unlocked = sem_post(sem);
          // expect(unlocked, equals(0));
          unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));

          // Close & expect 0
          final int closed = sem_close(sem);
          closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));

          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      Future<bool> spawn_secondary_isolate(String name) async {
        // The entry point for the isolate
        void secondary_isolate_entrypoint(SendPort sender) {
          Pointer<Char> _name = (name.toNativeUtf8()).cast();
          Pointer<sem_t> sem = sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, 1);

          int waited = sem_wait(sem);
          waited.isOdd || (throw Exception("sem_wait in secondary isolate should have expected 0, got $waited"));

          int closed = sem_close(sem);
          closed.isOdd || (throw Exception("sem_closed in secondary isolate should have expected 0, got $closed"));

          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '/${safeIntId.getId()}-named-sem';

      // Spawn the first helper isolate
      final result_one = spawn_primary_isolate(name);
      sleep(Duration(milliseconds: 250));
      final result_two = spawn_secondary_isolate(name);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two]);

      Pointer<Char> _name = (name.toNativeUtf8()).cast();
      final int unlinked = sem_unlink(_name);

      expect(unlinked, equals(0));
      expect(outcomes, everyElement(equals(true)));
    });

    test(
        'Several Isolates Accessing Same Named Semaphore, all with O_CREAT flag, waiting random durations and then unlocking.',
        () async {
      Future<bool> spawn_isolate(String name, int sem_open_value, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          Pointer<Char> _name = (name.toNativeUtf8()).cast();
          Pointer<sem_t> sem =
              sem_open(_name, SemOpenUnixMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, sem_open_value);

          sem.address != SemOpenUnixMacros.SEM_FAILED.address ||
              (throw Exception(
                  "sem_open in primary isolate should have succeeded, got ${SemOpenError.fromErrno(errno.value)}"));

          int waited = sem_wait(sem);

          waited.isEven || (throw Exception("sem_wait in isolate $id should have expected 0, got $waited"));

          // Waiting in primary isolate for 3 seconds.
          sleep(Duration(milliseconds: Random().nextInt(1000)));

          // Unlock
          final int unlocked = sem_post(sem);
          unlocked.isEven || (throw Exception("sem_post in primary isolate should have expected 0, got $unlocked"));

          // Close & expect 0
          final int closed = sem_close(sem);
          closed.isEven || (throw Exception("sem_closed in primary isolate should have expected 0, got $closed"));

          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '/${safeIntId.getId()}-named-sem';

      int sem_open_value = 1;
      // Spawn the first helper isolate
      final result_one = spawn_isolate(name, sem_open_value, 1);
      final result_two = spawn_isolate(name, sem_open_value, 2);
      final result_three = spawn_isolate(name, sem_open_value, 3);
      final result_four = spawn_isolate(name, sem_open_value, 4);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two, result_three, result_four]);

      Pointer<Char> _name = (name.toNativeUtf8()).cast();
      final int unlinked = sem_unlink(_name);

      expect(unlinked, equals(0));
      expect(outcomes, everyElement(equals(true)));
    });
  });
}
