import 'native_semaphore.dart' show NativeSemaphore;
import 'native_semaphore_operations.dart' show NativeSemaphoreProcessOperationStatus, NativeSemaphoreProcessOperationStatusState, NativeSemaphoreProcessOperationStatuses;
import 'persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;
import 'persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'semaphore_counter.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;

typedef I = SemaphoreIdentity;
typedef IS = SemaphoreIdentities<I>;
typedef CU = SemaphoreCountUpdate;
typedef CD = SemaphoreCountDeletion;
typedef CT = SemaphoreCount<CU, CD>;
typedef CTS = SemaphoreCounts<CU, CD, CT>;
typedef NSPOSS = NativeSemaphoreProcessOperationStatusState;
typedef NSPOS = NativeSemaphoreProcessOperationStatus<I, NSPOSS>;
typedef NSPOSES = NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>;
typedef CTR = SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>;
typedef CTRS = SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>;
typedef PNSO = PersistedNativeSemaphoreOperation;
typedef PNSOS = PersistedNativeSemaphoreOperations<PNSO>;
typedef PNSA = PersistedNativeSemaphoreAccessor;
typedef PNSM = PersistedNativeSemaphoreMetadata<PNSA>;

typedef NS = NativeSemaphore<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA>;
