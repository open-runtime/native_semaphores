
import 'native_semaphore.dart' show NativeSemaphore;
import 'persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'semaphore_counter.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;

typedef I = SemaphoreIdentity;
typedef IS = SemaphoreIdentities<I>;
typedef CU = SemaphoreCountUpdate;
typedef CD = SemaphoreCountDeletion;
typedef CT = SemaphoreCount<CU, CD>;
typedef CTS = SemaphoreCounts<CU, CD, CT>;
typedef CTR = SemaphoreCounter<I, CU, CD, CT, CTS>;
typedef CTRS = SemaphoreCounters<I, CU, CD, CT, CTS, CTR>;
typedef PNSO = PersistedNativeSemaphoreOperation;
typedef PNSOS = PersistedNativeSemaphoreOperations<PNSO>;
typedef NS = NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS>;
