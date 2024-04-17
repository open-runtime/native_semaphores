import 'dart:io' show Directory, File, FileMode, Platform, pid;

import '../runtime_native_semaphores.dart' show NATIVE_SEMAPHORE_OPERATION_STATUS;
import 'semaphore_identity.dart' show SemaphoreIdentity;

// Enum to represent types of operations i.e. LOCK, UNLOCK, CREATE, DISPOSE

// Singleton class to store metadata about the persisted semaphores in system temporary directory.
class SemaphoreMetadata {
  static final Map<String, SemaphoreIdentity> identities = {};
  static final Map<String, File> statuses = {};
  static final Map<String, int> _counts = {};

  static const prefix = 'runtime_native_semaphores';

  // TODO incrementor here

  static final Directory root = Directory([Directory.systemTemp.path, prefix].join(Platform.pathSeparator))
    ..createSync(recursive: true);

  SemaphoreMetadata();

  SemaphoreIdentity register({required SemaphoreIdentity identity}) {
    return identities.putIfAbsent(identity.semaphore, () => identity);
  }

  static int locks({required SemaphoreIdentity identity}) {
    // print("From locks: ${_counts[identity.semaphore]} ${identity.semaphore}");
    final int? count = _counts[identity.semaphore];
    if (count is int)
      return count;
    else
      return _counts.putIfAbsent(identity.semaphore, () => 0);
  }

  static int increment({required SemaphoreIdentity identity}) {
    int count = _counts[identity.semaphore] ?? (throw Exception('Failed to get semaphore count.'));
    // Increment the semaphore count
    int total = count + 1;

    print("From increment: ${count} to ${total}");
    (total - count) <= 1 || (throw Exception('Failed to increment semaphore count.'));
    return _counts[identity.semaphore] = total;
  }

  static decrement({required SemaphoreIdentity identity}) {
    // Decrement the semaphore count i.e. identity.locks
    int count = _counts[identity.semaphore] ?? (throw Exception('Failed to get semaphore count.'));
    int total = count - 1;
    (count - total) <= 1 || (throw Exception('Failed to decrement semaphore count.'));
    print("From decrement: ${count} to ${total}");
    return _counts[identity.semaphore] = total;
  }

  static bool persist({required SemaphoreIdentity identity, required NATIVE_SEMAPHORE_OPERATION_STATUS status}) {
    // probably persist counts
    String uuid = identity.uuid();
    return statuses
        .putIfAbsent(
            uuid,
            () =>
                (File([root.path, '$uuid.${status.name.toLowerCase()}.status'].join(Platform.pathSeparator))..createSync(recursive: true, exclusive: true))
                  ..writeAsStringSync(SemaphoreMetadata.locks(identity: identity).toString(),
                      flush: true, mode: FileMode.writeOnlyAppend))
        .existsSync();
  }

  static clean({required NATIVE_SEMAPHORE_OPERATION_STATUS operation}) {
    // root.deleteSync(recursive: true);
  }

  aggregate() {
    //  Get current running total of semaphores
  }
}
