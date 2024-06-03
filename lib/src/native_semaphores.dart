import '../runtime_native_semaphores.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts, SemaphoreIdentities, SemaphoreIdentity;
import 'native_semaphore.dart' show NativeSemaphore;
import 'native_semaphore_operations.dart' show NativeSemaphoreProcessOperationStatus, NativeSemaphoreProcessOperationStatusState, NativeSemaphoreProcessOperationStatuses;
import 'persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;
import 'persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;

// A wrapper to track the instances of the native semaphore
class NativeSemaphores<I extends SemaphoreIdentity, IS extends SemaphoreIdentities<I>, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>, CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>, PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>, PNSA extends PersistedNativeSemaphoreAccessor, PNSM extends PersistedNativeSemaphoreMetadata<PNSA>, NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA>> {
  static final Map<String, dynamic> __instantiations = {};

  final Map<String, dynamic> _instantiations = NativeSemaphores.__instantiations;

  Map<String, dynamic> get all => Map.unmodifiable(_instantiations);

  bool has<T>({required String hash}) => _instantiations.containsKey(hash) && _instantiations[hash] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  NS get({required String hash}) => _instantiations[hash] ?? (throw Exception('Failed to get semaphore counter for $hash. It doesn\'t exist.'));

  NS register({required NS semaphore}) {
    print("registering semaphore for ${semaphore.hash}");
    (_instantiations.containsKey(semaphore.hash) || semaphore != _instantiations[semaphore.hash]) || (throw Exception('Failed to register semaphore counter for $semaphore.hash. It already exists or is not the same as the inbound identity being passed.'));

    return _instantiations.putIfAbsent(semaphore.hash, () => semaphore);
  }

  void delete({required String hash}) {
    _instantiations.containsKey(hash) || (throw Exception('Failed to delete semaphore counter for $hash. It doesn\'t exist.'));
    _instantiations.remove(hash);
  }

  String toString() => 'NativeSemaphores(all: ${all.toString()})';
}
