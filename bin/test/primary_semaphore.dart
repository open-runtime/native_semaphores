import 'dart:io' show exit, pid, stdout;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

main(List<String> args) async {
  String name = args.elementAt(0);

  int lock_delay = int.parse(args.elementAt(1));
  int unlock_delay = int.parse(args.elementAt(2));

  String tracker = args.elementAt(3);

  stdout.writeln('Child Process Parameters Lock Delay: $lock_delay, Unlock Delay: $unlock_delay, Tracker: $tracker, PID: $pid, Name: $name');

  stdout.writeln('Creating semaphore with name: $name');

  final NativeSemaphore sem = NativeSemaphore.instantiate(name: name)..open();

  await Future.delayed(Duration(seconds: lock_delay));

  Stopwatch stopwatch = Stopwatch()..start();
  sem.lock();
  stopwatch.stop();

  stdout.writeln('Child Process $tracker $pid Locking semaphore with name $name took: [${stopwatch.elapsed.inSeconds}] seconds');

  await Future.delayed(Duration(seconds: unlock_delay));

  sem.unlock();

  stdout.writeln('Semaphore unlocked with name: $name');

  sem.close();

  stdout.writeln('Semaphore closed with name: $name');

  sem.unlink();

  stdout.writeln('Semaphore unlinked with name: $name');

  exit(0);

}
