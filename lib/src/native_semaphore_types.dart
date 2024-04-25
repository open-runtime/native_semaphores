import 'native_semaphore.dart' show NativeSemaphore;
import 'semaphore_counter.dart' show SemaphoreCount, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;

typedef I = SemaphoreIdentity;
typedef IS = SemaphoreIdentities<I>;
typedef CT = SemaphoreCount;
typedef CTS = SemaphoreCounts<CT>;
typedef CTR = SemaphoreCounter<I, CT, CTS>;
typedef CTRS = SemaphoreCounters<I, CT, CTS, CTR>;
typedef NS = NativeSemaphore<I, IS, CT, CTS, CTR, CTRS>;
