// // Mostly determined by counters
// import 'native_semaphore.dart' show ProtectedNativeSemaphoreStatus;
//
// enum NATIVE_SEMAPHORE_STATUS {
//   GLOBALLY_LOCKED,
//   /*Can't lock across processes as another process is holding */
//
//   INTERNALLY_LOCKED,
//   /* Can lock internally */
//
//   INTERNALLY_LOCKING,
//
//   GLOBALLY_LOCKING,
//
//   /*Can lock across processes */
//   GLOBALLY_UNLOCKED,
//
//   INTERNALLY_UNLOCKED,
//   /*Can lock across processes */
//
//   INTERNALLY_UNLOCKING,
//
//   GLOBALLY_UNLOCKING,
//
//   GLOBALLY_CLOSING,
//
//   GLOBALLY_CLOSED,
//
//   GLOBALLY_UNLINKING,
//   /* This can only happen once on a semaphore across the OS and so unlinking internally effectively does nothing */
//
//   GLOBALLY_UNLINKED,
//   /* If we have unlinked this semaphore across the OS */
//
//   READY,
//   TERMINATED,
// }
//
// class NativeSemaphoreStatus {
//   late final NATIVE_SEMAPHORE_STATUS internal;
//   late final NATIVE_SEMAPHORE_STATUS global;
//   late final NATIVE_SEMAPHORE_STATUS intermittent;
//   late final NATIVE_SEMAPHORE_STATUS current;
//
//   NativeSemaphoreStatus._(ProtectedNativeSemaphoreStatus protected) {
//     internal = protected.internal;
//     global = protected.global;
//     intermittent = protected.intermittent;
//     current = protected.current;
//   }
//
//   factory NativeSemaphoreStatus(ProtectedNativeSemaphoreStatus protected) => NativeSemaphoreStatus._(protected);
//
//   static NativeSemaphoreStatus immutable(ProtectedNativeSemaphoreStatus protected) => NativeSemaphoreStatus(protected);
// }
