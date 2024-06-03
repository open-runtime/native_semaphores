import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform, Process, ProcessResult, stderr;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;
import 'package:chalkdart/chalk.dart' show Chalk, chalk;
// import 'package:chalkdart/chalkstrings.dart';

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart'
    show
        NativeSemaphore,
        SemaphoreCount,
        SemaphoreCountDeletion,
        SemaphoreCountUpdate,
        SemaphoreCounter,
        SemaphoreCounters,
        SemaphoreCounts,
        SemaphoreIdentities,
        SemaphoreIdentity;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show I, PNSOS;
import 'package:runtime_native_semaphores/src/persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor;
import 'package:runtime_native_semaphores/src/persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart' show anyOf, equals, everyElement, expect, group, isNot, isTrue, setUp, test;

void main() {
  String process_name = 'bin${Platform.pathSeparator}test${Platform.pathSeparator}persisted_semaphore${Platform.isWindows ? '.exe' : ''}';

  String padded_output(String input, {int width = 36}) {
    // Use regex to extract ALIGNED_SUFFIX:[0.002s] and remove it from the input
    String suffix = RegExp(r"ALIGNED_SUFFIX:\[(\d+\.\d+)s\]").firstMatch(input)?.group(0) ?? '';

    input = input.replaceAll(suffix, '');
    suffix = suffix.replaceAll('ALIGNED_SUFFIX:[', '(Op. took ').replaceAll(']', ')');

    if (input.length >= width) {
      return input;
    }

    int total = width - input.length;
    int left = total ~/ 2;
    int right = total - left;

    String _left = ' ' * left;
    String _right = ' ' * right;

    String returnable = '$input$_left$_right';

    return suffix.isNotEmpty ? '$input$_left$_right'.replaceRange(returnable.length - '  $suffix'.length, returnable.length, suffix.isNotEmpty ? '  $suffix' : '  ') : returnable;
  }

  DateTime timeframe = DateTime.now();
  List<Chalk> colors = [
    chalk.blue,
    chalk.cyan,
    chalk.green,
    chalk.magenta,
    chalk.red,
    chalk.yellow,
    chalk.white,
    chalk.black,
    chalk.brightBlue,
    chalk.brightCyan,
    chalk.brightGreen,
    chalk.brightMagenta,
    chalk.brightRed,
    chalk.brightYellow,
    chalk.brightWhite,
    chalk.brightBlack
  ];

  String Function(DateTime timestamp) timestamp_formatter = (DateTime timestamp) {
    late Chalk color;

    // print(timestamp.difference(timeframe).inMilliseconds);

    timestamp.difference(timeframe).inMilliseconds > 200 ? (timeframe = DateTime.now()) is DateTime && (color = colors.removeAt(0)) is Chalk : color = colors.first;

    return color('${(12 - timestamp.toLocal().hour).abs()}:${timestamp.toLocal().minute}:${timestamp.toLocal().second}:${timestamp.toLocal().millisecond}');
  };

  ({DateTime timestamp, String output}) print_process_outputs_headers(List<String> tracers, List<Chalk> colors, DateTime? timestamp) {
    // regex to match inner text between [ ] brackets
    String Function(String output) tracer_extractor = (String output) => output.substring(output.indexOf('(') + 1, output.indexOf(')'));

    timestamp ??= DateTime.now();

    return (
      timestamp: timestamp,
      output:
          '${padded_output(timestamp_formatter(timestamp), width: 22)} | ${colors[0]((padded_output(tracer_extractor(tracers[0]))))} | ${colors[1](padded_output(tracer_extractor(tracers[1])))} | ${colors[2](padded_output(tracer_extractor(tracers[2])))} |'
    );
  }

  ({DateTime timestamp, String output}) print_process_outputs(List<String> tracers, Chalk color, String tracer, String message, DateTime? timestamp) {
    timestamp ??= DateTime.now();
    return (
      timestamp: timestamp,
      output:
          '${padded_output(timestamp_formatter(timestamp), width: 22)} | ${color(padded_output(tracers[0] == tracer ? message : ''))} | ${color(padded_output(tracers[1] == tracer ? message : ''))} | ${color(padded_output(tracers[2] == tracer ? message : ''))} |'
    );
  }

  setUp(() async {
    File semaphore_executable = File(process_name);

    // if (!semaphore_executable.existsSync()) {
    ProcessResult compiling_semaphore_executable =
        Process.runSync('dart', ['compile', 'exe', 'bin${Platform.pathSeparator}test${Platform.pathSeparator}persisted_semaphore.dart', '-o', process_name]);

    print('Successfully compiled semaphore_executable: ${compiling_semaphore_executable.stdout}');

    semaphore_executable.existsSync() || (throw Exception("Persisted semaphore executable should exist."));
    // } else {
    //   print('Persisted semaphore executable was found and already compiled. Be sure you haven\'t made changes and need to compile again.');
    // }
  });

  group('Testing Persisted Native Semaphore from current thread', () {
    test('Create Native Semaphore, Call open(), and verify that the file exists.', () async {
      String name = 'tested_named_sem';

      NativeSemaphore semaphore = NativeSemaphore.instantiate(name: name, verbose: true, tracerFn: () => chalk.blue('Semaphore'));

      // Expect the cache directory to exist
      expect(semaphore.identity.cache.existsSync(), equals(true));

      // Expect the temp file to exist
      expect(semaphore.identity.temp.existsSync(), equals(true));

      // Expect operations to not be set
      expect(semaphore.operations.isSet, equals(false));
      expect(semaphore.operations.get, equals(null));

      // Expect operation to also not be set
      expect(semaphore.operations.isSet, equals(false));
      expect(semaphore.operations.get, equals(null));

      // Open the semaphore
      bool opened = semaphore.open();

      // Expect the semaphore to be opened
      expect(opened, equals(true));

      // Expect the operations to be set
      expect(semaphore.operations.isSet, equals(true));
      expect(semaphore.operations.get, isNot(equals(null)));

      // Expect the operation to be set
      expect(semaphore.operations.isSet, equals(true));
      expect(semaphore.operations.get, isNot(equals(null)));

      // Read the operations from disk and compare
      PNSOS operations =
          PersistedNativeSemaphoreOperations.rehydrate(serialized: semaphore.identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate);

      // there should be 3 operations for an open call
      expect(operations.iterable.length, equals(3));
      expect(semaphore.operations.get?.indexed, equals(operations.indexed));
      expect(semaphore.operations.get.toString(), equals(operations.toString()));

      // Lock the semaphore
      bool locked = semaphore.lock();
      expect(locked, equals(true));

      // Examine operations
      operations = PersistedNativeSemaphoreOperations.rehydrate(serialized: semaphore.identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate);

      expect(operations.iterable.length, equals(6));
      expect(semaphore.operations.get?.indexed, equals(operations.indexed));
      expect(semaphore.operations.get.toString(), equals(operations.toString()));

      // Shutdown
      semaphore
        ..unlock()
        ..close()
        ..unlink();
    });
  }, skip: true);

  group('Testing Persisted Native Semaphore across processes', () {
    test(
        'Kick off several processes that use the same semaphore name and verify the Identity.synchronize function picks them up and registers them/updates their counts, and they detect the semaphore instance from this process',
        () async {
      String name = '${safeIntId.getId()}_named_sem';
      bool continuous_printing = false;

      String main_tracer = chalk.brightYellow('(MAIN_PROCESS)');
      String first_tracer = chalk.brightGreen('(FIRST_PROCESS)');
      String second_tracer = chalk.brightMagenta('(SECOND_PROCESS)');
      List<({DateTime timestamp, String output})> prints = List<({DateTime timestamp, String output})>.empty(growable: true);

      prints.add(print_process_outputs_headers([main_tracer, first_tracer, second_tracer], [chalk.brightYellow, chalk.brightGreen, chalk.brightMagenta], null));

      if (continuous_printing) print(prints.last.output);
      //
      // Completer<String> first_process_attempting_open_completer = Completer<String>();
      // Completer<String> second_process_attempting_open_completer = Completer<String>();
      // Completer<String> main_process_attempting_open_completer = Completer<String>();

      // It should take roughly 2-3 seconds to lock the second process
      Completer<DateTime> first_process_attempting_locked_completer = Completer<DateTime>();
      Completer<DateTime> second_process_attempting_locked_completer = Completer<DateTime>();
      Completer<DateTime> main_process_attempting_lock_completer = Completer<DateTime>();

      Completer<DateTime> first_process_locked_completer = Completer<DateTime>();
      Completer<DateTime> second_process_locked_completer = Completer<DateTime>();
      Completer<DateTime> main_process_locked_completer = Completer<DateTime>();

      Completer<DateTime> first_process_unlocked_completer = Completer<DateTime>();
      Completer<DateTime> second_process_unlocked_completer = Completer<DateTime>();
      Completer<DateTime> main_process_unlocked_completer = Completer<DateTime>();

      Completer<({DateTime time, String tracker})> first_process_ensured_order = Completer<({DateTime time, String tracker})>();
      Completer<({DateTime time, String tracker})> second_process_ensured_order = Completer<({DateTime time, String tracker})>();
      Completer<({DateTime time, String tracker})> main_process_ensured_order = Completer<({DateTime time, String tracker})>();

      List<({DateTime time, String tracker})> resolutions = List<({DateTime time, String tracker})>.empty(growable: true);

      first_process_locked_completer.future.then((_) => first_process_ensured_order.complete((resolutions..add((time: _, tracker: first_tracer))).last));
      second_process_locked_completer.future.then((_) => second_process_ensured_order.complete((resolutions..add((time: _, tracker: second_tracer))).last));
      main_process_locked_completer.future.then((_) => main_process_ensured_order.complete((resolutions..add((time: _, tracker: main_tracer))).last));

      Completer<void> first_process_exiting_completer = Completer<void>();
      Completer<void> second_process_exiting_completer = Completer<void>();
      Completer<void> main_process_exiting_completer = Completer<void>();

      // bool Function(String output) attempting_open_matcher = (String output) => output.contains('Attempting to open semaphore with name $name');

      bool Function(String output) attempting_locked_matcher = (String output) => output.contains('Attempting to lock semaphore with name $name and tracer');

      bool Function(String output) locked_matcher = (String output) => output.contains('Locking semaphore with name $name took: [');
      bool Function(String output) unlocked_matcher = (String output) => output.contains('NOTIFICATION: Semaphore unlocked with name:');

      bool Function(String output) delay_matcher = (String output) => output.contains('semaphore with name $name is delayed by: [');

      String Function(String output) lock_time_extractor =
          (String output) => RegExp(r"semaphore with name \d+_named_sem took: \[(\d+)\] seconds").firstMatch(output)?.group(1) ?? '-1';

      String Function(String output) delay_time_extractor =
          (String output) => RegExp(r"semaphore with name \d+_named_sem is delayed by: \[(\d+)\] seconds").firstMatch(output)?.group(1) ?? '-1';

      List<({bool matched, String? tracer, String? position, String? elapsed})> Function(String output) waiting_time_extractor = (String output) {
        return output
            .split('|')
            .map((element) {
              // regex to specifically pull out content within the brackets between "waiting_on: [(FIRST_PROCESS)]" where it returns (FIRST_PROCESS)
              String waiting_on_tracer = element.split('waiting_on: [').last.split(']').first;
              // regex to pull out at the value between the brackets  "position: [1]" where it returns 1
              RegExpMatch? waiting_position = RegExp(r"at position: \[(\d+)\]").firstMatch(element);
              // regex to pull out the value between the brackets "for duration: [2.001]s" where it returns 2.001
              RegExpMatch? waiting_duration = RegExp(r"for duration: \[(\d+\.\d+)\]s").firstMatch(element);

              return (
                matched: waiting_position is RegExpMatch && waiting_duration is RegExpMatch,
                tracer: '$waiting_on_tracer',
                position: waiting_position?.group(1),
                elapsed: waiting_duration?.group(1) ?? '-1'
              );
            })
            .where((element) => element.matched)
            .toList();
      };

      String Function(String seconds, String tracer) seconds_emitter = (String seconds, String tracer) => seconds;

      String Function(String message, String tracer) locked_emitter = (String message, String tracer) => message;

      Map<String, Set<String>> outputs = Map<String, Set<String>>();

      Map<String, List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})>> timed_outputs =
          Map<String, List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})>>();

      ({bool added, String mapping, DateTime? timestamp}) add_to_outputs(String message, String matcher, String mapping, String tracer, DateTime? timestamp) {
        outputs.putIfAbsent(tracer, () => Set<String>());
        if (message.contains(matcher) && !outputs[tracer]!.contains(mapping)) {
          outputs[tracer]!.add(mapping);
          return (added: true, mapping: mapping, timestamp: timestamp ?? DateTime.now());
        }

        return (added: false, mapping: '', timestamp: null);
      }

      ;

      List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})> mapped_output(
        String message,
        String tracer,
        Completer<DateTime> attempting_locked_completer,
        Completer<DateTime> locked_completer,
        Completer<DateTime> unlocked_completer,
      ) {
        DateTime? timestamp = message.split('=').first.isNotEmpty ? DateTime.tryParse(message.split('=').first) : null;
        message = message.split('=').last;

        List<({bool added, String mapping, DateTime? timestamp})> _added = List<({bool added, String mapping, DateTime? timestamp})>.from([
          ...(outputs.containsKey(tracer) && !outputs[tracer]!.contains('LOCKED')
              ? waiting_time_extractor(message).map((element) {
                  return add_to_outputs(
                      message,
                      message,
                      'AWAIT ${element.tracer} (${element.position}) ${element.elapsed}s' +
                          List.filled((44 - 'AWAIT ${element.tracer} (${element.position}) ${element.elapsed}s'.length), ' ').join("") +
                          ' ',
                      tracer,
                      timestamp);
                })
              : []),
          // message.contains("waiting_on:") ? [] : (added: false, mapping: '', timestamp: null),
          add_to_outputs(message, 'opened: true', 'OPENED', tracer, timestamp),
          add_to_outputs(message, 'locked: true', 'LOCKED', tracer, timestamp),
          attempting_locked_matcher(message)
              ? add_to_outputs(message, 'NOTIFICATION: Attempting to lock semaphore with name', 'ATTEMPTING LOCK', tracer, timestamp)
              : (added: false, mapping: '', timestamp: null),
          locked_matcher(message)
              ? add_to_outputs(message, 'took: [${lock_time_extractor(message)}] seconds', 'LOCKING TOOK ${lock_time_extractor(message)}s', tracer, timestamp)
              : (added: false, mapping: '', timestamp: null),
          delay_matcher(message)
              ? add_to_outputs(message, 'NOTIFICATION: Locking semaphore with name ${name} is delayed by: [${delay_time_extractor(message)}] seconds',
                  'LOCKING IN ${delay_time_extractor(message)}s', tracer, timestamp)
              : (added: false, mapping: '', timestamp: null),
          delay_matcher(message)
              ? add_to_outputs(message, 'NOTIFICATION: Unlocking semaphore with name ${name} is delayed by: [${delay_time_extractor(message)}] seconds',
                  'UNLOCKING IN ${delay_time_extractor(message)}s', tracer, timestamp)
              : (added: false, mapping: '', timestamp: null),
          add_to_outputs(message, 'waiting: true', 'WAITING TO LOCK', tracer, timestamp),
          add_to_outputs(message, 'unlocked: true', 'UNLOCKED', tracer, timestamp),
          add_to_outputs(message, 'NOTIFICATION: Semaphore unlocked with name:', 'UNLOCKED', tracer, timestamp),
          add_to_outputs(message, 'closed: true', 'CLOSED', tracer, timestamp),
          add_to_outputs(message, 'unlinked: true', 'UNLINKED', tracer, timestamp)
        ]);

        List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})> __added = _added.where((element) => element.added).map((element) {
          timed_outputs.putIfAbsent(tracer, () => List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})>.empty(growable: true));
          ({bool added, String mapping, DateTime? timestamp, Duration? elapsed})? _previous = timed_outputs[tracer]!.isNotEmpty ? timed_outputs[tracer]!.last : null;
          ({bool added, String mapping, DateTime? timestamp, Duration? elapsed}) _element =
              (added: element.added, mapping: element.mapping, timestamp: element.timestamp, elapsed: _previous != null ? DateTime.now().difference(_previous.timestamp!) : null);
          timed_outputs[tracer]!.add(_element);

          if (element.mapping.contains('LOCKED') && !locked_completer.isCompleted) (locked_completer..complete(element.timestamp)).future;
          if (element.mapping.contains('UNLOCKED') && !unlocked_completer.isCompleted) (unlocked_completer..complete(element.timestamp)).future;
          if (element.mapping.contains('ATTEMPTING LOCK') && !attempting_locked_completer.isCompleted) (attempting_locked_completer..complete(element.timestamp)).future;

          return _element;
        }).toList();

        return __added.where((element) => element.added).toList();
      }

      ;

      void emitter(String output, String tracer, Chalk color, Completer<DateTime> attempting_locked_completer, Completer<DateTime> locked_completer,
          Completer<DateTime> unlocked_completer) {
        List<({bool added, String mapping, DateTime? timestamp, Duration? elapsed})> _outputs =
            mapped_output(output, tracer, attempting_locked_completer, locked_completer, unlocked_completer);
        _outputs.forEach((_output) {
          prints
            ..add(print_process_outputs([main_tracer, first_tracer, second_tracer], color, tracer,
                _output.added ? _output.mapping + (_output.elapsed is Duration ? ' ALIGNED_SUFFIX:[${_output.elapsed!.inMilliseconds / 1000}s]' : '') : '', _output.timestamp));

          if (continuous_printing) print(prints.last.output);
        });
      }

      bool process_listener(Stream<List<int>> output, Completer<DateTime> attempting_locked_completer, Completer<DateTime> locked_completer, Completer<DateTime> unlocked_completer,
          Completer<void> exiting_completer, String tracer, Chalk color) {
        output.transform(utf8.decoder).listen((_output) {
          List<String> _outputs = _output.contains(Platform.lineTerminator) ? const LineSplitter().convert(_output) : [_output];
          _outputs.forEach((line) {
            if (line.isNotEmpty && (line.contains('STATE:') || line.contains('NOTIFICATION:')))
              emitter(line, tracer, color, attempting_locked_completer, locked_completer, unlocked_completer);
            // if (line.isNotEmpty && !continuous_printing) print(tracer + line);
          });
        }, onDone: exiting_completer.complete);

        return true;
      }

      Future<Process> first_process = Process.start(
        process_name,
        [
          name,
          /*We lock right away */ '0',
          /* We unlock 5 seconds later */ '5',
          /* tracer  */ first_tracer,
        ],
      );

      Future<Process> second_process = Process.start(process_name, [
        name,
        /* We lock 2-3 seconds into the first processes unlock delay Note: it can take up to 1 second for the process to launch */
        '2',
        /* We unlock roughly 2 seconds later */
        '4',
        /* tracer  */
        second_tracer
      ]);

      first_process.then((Process process) => process_listener(process.stdout, first_process_attempting_locked_completer, first_process_locked_completer,
          first_process_unlocked_completer, first_process_exiting_completer, first_tracer, chalk.brightGreen));

      second_process.then((Process process) => process_listener(process.stdout, second_process_attempting_locked_completer, second_process_locked_completer,
          second_process_unlocked_completer, second_process_exiting_completer, second_tracer, chalk.brightMagenta));

      final NativeSemaphore sem = NativeSemaphore.instantiate(name: name, tracerFn: () => main_tracer, verbose: false);

      process_listener(sem.logs.stream.map((event) => DateTime.now().toIso8601String() + '=' + event).transform(utf8.encoder), main_process_attempting_lock_completer,
          main_process_locked_completer, main_process_unlocked_completer, main_process_exiting_completer, main_tracer, chalk.brightYellow);

      sem.open();

      await first_process_locked_completer.future;
      await sem.lockWithDelay(
          delay: Duration(seconds: 3),
          before: () async {
            await main_process_attempting_lock_completer.future;
          });

      // expect(sem.identity.instances<I>().all.length, equals(3));
      // expect(sem.identity.instances<I>().external.length, equals(2));
      // expect(sem.identity.instances<I>().internal.length, equals(1));

      await sem.unlockWithDelay(delay: Duration(seconds: 3));

      // Kill the processes
      bool first_killed = await (await first_process).exitCode == 0;
      prints
        ..add(print_process_outputs(
            [main_tracer, first_tracer, second_tracer], chalk.brightYellow, first_tracer, 'KILLED: ${first_killed} ${await (await first_process).exitCode}', null));

      if (continuous_printing) print(prints.last.output);

      bool second_killed = await (await second_process).exitCode == 0;
      prints
        ..add(print_process_outputs(
            [main_tracer, first_tracer, second_tracer], chalk.brightMagenta, second_tracer, 'KILLED: ${second_killed} ${await (await second_process).exitCode}', null));

      if (continuous_printing) print(prints.last.output);

      expect(first_killed, equals(true));
      expect(second_killed, equals(true));

      await main_process_locked_completer.future;

      expect(sem.close(), isTrue);
      expect(sem.unlink(), isTrue);

      await main_process_exiting_completer.future;

      if (!continuous_printing) (prints.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp))).forEach((element) => print(element.output));

      print('${Platform.lineTerminator}${Platform.lineTerminator}');

      print('Resolution Order: ${(resolutions..sort((a, b) => a.time.compareTo(b.time))).map((e) => e.tracker).join(' -> ')}');

      int first_process_lock_duration = (await first_process_unlocked_completer.future).difference(await first_process_locked_completer.future).inSeconds;
      int second_process_lock_duration = (await second_process_unlocked_completer.future).difference(await second_process_locked_completer.future).inSeconds;
      int main_process_lock_duration = (await main_process_unlocked_completer.future).difference(await main_process_locked_completer.future).inSeconds;

      int first_process_lock_time = (await first_process_locked_completer.future).difference(await first_process_attempting_locked_completer.future).inSeconds;
      int second_process_lock_time = (await second_process_locked_completer.future).difference(await second_process_attempting_locked_completer.future).inSeconds;
      int main_process_lock_time = (await main_process_locked_completer.future).difference(await main_process_attempting_lock_completer.future).inSeconds;

      print('${Platform.lineTerminator}');

      print(first_tracer + " was locked for " + (first_process_lock_duration).toString() + " seconds and took " + (first_process_lock_time).toString() + " seconds to lock.");
      print(second_tracer + " was locked for " + (second_process_lock_duration).toString() + " seconds and took " + (second_process_lock_time).toString() + " seconds to lock.");
      print(main_tracer + " was locked for " + (main_process_lock_duration).toString() + " seconds and took " + (main_process_lock_time).toString() + " seconds to lock.");

      expect(first_process_lock_time, equals(0));
      expect(second_process_lock_time, equals(3));
      expect(main_process_lock_time, equals(6));
    });
  });
}
