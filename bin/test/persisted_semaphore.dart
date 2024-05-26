import 'dart:async';
import 'dart:io' show exit, pid, stdout;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';


main(List<String> args) async {
  String name = args.elementAt(0);
  int lock_delay = int.parse(args.elementAt(1));
  int unlock_delay = int.parse(args.elementAt(2));
  String tracer = args.elementAt(3);

  // Completer<void> attempting_open_completer = Completer<void>();
  Completer<void> opened_completer = Completer<void>();
  Completer<void> attempting_lock_completer = Completer<void>();
  Completer<void> locked_completer = Completer<void>();
  Completer<void> lock_acquired_completer = Completer<void>();
  Completer<void> lock_delay_completer = Completer<void>();
  Completer<void> unlock_delay_completer = Completer<void>();
  Completer<void> unlocked_completer = Completer<void>();
  Completer<void> waiting_completer = Completer<void>();
  Completer<void> closed_completer = Completer<void>();
  Completer<void> unlinked_completer = Completer<void>();

  bool Function(String output) attempting_locked_matcher = (String output) => output.contains('Attempting to lock semaphore with name $name and tracer');
  bool Function(String output) locked_matcher = (String output) => output.contains('Locking semaphore with name $name took: [');
  bool Function(String output) delay_matcher = (String output) => output.contains('semaphore with name $name is delayed by: [');
  // bool Function(String output) attempting_open_matcher = (String output) => output.contains('Attempting to open semaphore with name $name');
  late StreamSubscription<String> subscription;
  emit(NativeSemaphore sem) {
    subscription = sem.logs.stream.listen((log) {
      // stdout.writeln(log);
      // if(attempting_open_matcher(log) && !attempting_open_completer.isCompleted) attempting_open_completer.complete(stdout..writeln(log));
      if(log.contains("NOTIFICATION: Predecessors")) stdout.writeln(DateTime.now().toIso8601String() + '=' + log);
      // if(log.contains("DEBUG:")) stdout.writeln(log);
      // if(log.contains("DEBUG:")) stdout.writeln(log + ' $tracer');
      if (log.contains("opened: true") && !opened_completer.isCompleted) opened_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains("locked: true") && !locked_completer.isCompleted) locked_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains("closed: true") && !closed_completer.isCompleted) closed_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains("unlinked: true") && !unlinked_completer.isCompleted) unlinked_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if ( log.contains("waiting: true") && !waiting_completer.isCompleted) waiting_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains("unlocked: true") && !unlocked_completer.isCompleted) unlocked_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (attempting_locked_matcher(log) && !attempting_lock_completer.isCompleted) attempting_lock_completer.complete((DateTime.now().toIso8601String() + '=' + log));
      if (locked_matcher(log) && !lock_acquired_completer.isCompleted) lock_acquired_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains('Locking semaphore with name') && delay_matcher(log) && !lock_delay_completer.isCompleted) lock_delay_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      if (log.contains('Unlocking semaphore with name') &&  delay_matcher(log) && !unlock_delay_completer.isCompleted) unlock_delay_completer.complete(stdout..writeln((DateTime.now().toIso8601String() + '=' + log)));
      // await stdout.flush();
    },onDone: () {
      subscription.cancel();
      // stdout.writeln('Done');
    });
  }


  final NativeSemaphore sem = NativeSemaphore.instantiate(name: name, tracer: tracer);
  emit(sem);


  sem.open();

  await stdout.flush();

  await sem.lockWithDelay(delay: Duration(seconds: lock_delay));

  await locked_completer.future;

  // Critical to keep for unit test. We parse out the time and assert that it is within a certain range
  await sem.unlockWithDelay(delay: Duration(seconds: unlock_delay));

  await unlocked_completer.future;

  stdout.writeln('DEBUG: $tracer Waiting for semaphore to close');

  sem.close();

  await closed_completer.future;

  stdout.writeln('DEBUG: $tracer Waiting for semaphore to unlink');

  sem.unlink();

  await unlinked_completer.future;

  stdout.writeln('DEBUG: $tracer Waiting for semaphore to exit');

  exit(0);
}
