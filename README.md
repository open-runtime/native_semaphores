# runtime_native_semaphores ⎹ By [Pieces for Developers](https://pieces.app)

[![Native Named Semaphores](https://github.com/open-runtime/native_semaphores/actions/workflows/workflow.yaml/badge.svg)](https://github.com/open-runtime/native_semaphores/actions/workflows/workflow.yaml)

## Overview

The `runtime_native_semaphores` package provides a Dart interface for utilizing native semaphore mechanisms, allowing for efficient cross-process and cross-isolate synchronization. 
This package is particularly useful in scenarios where multiple Dart isolates or even separate processes i.e. (AOTs) need to coordinate access to shared resources without 
stepping on each other's toes. By leveraging native operating system semaphores, `runtime_native_semaphores` ensures that synchronization is both robust and performant.

## Use Cases
- **Cross-Isolate Synchronization**: Use named semaphores to synchronize and coordinate atomic actions such as database writes, file access, or other shared resources across different Dart isolates within the same application.
- **Cross-Process Thread Synchronization**: In applications that span multiple processes i.e. cooperating AOTs, named semaphores can ensure that only one process accesses a critical resource/section of code at a time, preventing race conditions and ensuring data integrity.

## Platform Support
The `runtime_native_semaphores` package supports the following platforms:
- MacOS (x86_64, arm64)
- Linux (x86_64, arm64)
- Windows (x86_64)

--- 

## Installation
To add `runtime_native_semaphores` to your Dart package, include it in your `pubspec.yaml` file:

```yaml
dependencies:
  runtime_native_semaphores: ^0.0.3
```

## Getting Started
The `runtime_native_semaphores` package provides a unified API for working with named semaphores across different MacOS (x86_64, arm64), Linux (x86_64, arm64) and Windows platforms.
The package exposes a `NativeSemaphore` class that can be used to create, open, lock, unlock, manage and dispose, named semaphores.

### Creating a Named Semaphore
The following example demonstrates how to create a semaphore, lock and unlock it within different Dart isolates. This is useful in scenarios where resources are shared across isolates or processes.

```dart
import 'dart:isolate';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;

void main() {
  // Create a unique identifier for the semaphore 
  // I's suggest using an safe integer identifier from 
  // [safe_int_id](https://pub.dev/packages/safe_int_id)
  final String name = 'my-native-named-semaphore-identifier';
  
  spawnIsolate(name, 1);
  spawnIsolate(name, 2);
  // Add more isolates as needed
}

Future<void> spawnIsolate(String name, int isolate) async {
  void isolateEntryPoint(SendPort sendPort) {
    final sem = NativeSemaphore(identifier: name);
    
    if (!sem.lock()) {
      throw Exception("Failed to lock semaphore in isolate $isolate");
    }
    
    // Perform work here...i.e. a random blocking operation
    sleep(Duration(milliseconds: Random().nextInt(500)));
    
    if (!sem.unlock()) {
      throw Exception("Failed to unlock semaphore in isolate $isolate");
    }
    
    sendPort.send(true);
  }

  final receivePort = ReceivePort();
  await Isolate.spawn(isolateEntryPoint, receivePort.sendPort);
  await receivePort.first;
  //...
  
  // Cleanup
  sem.dispose();
  receivePort.close();
    
}
```

## **_API Reference:_**
### **Main Class**
- `NativeSemaphore({required String identifier})`: Creates a new semaphore with the given identifier.

### **Methods**:

#### **Locking**
- `bool lock()`: Locks the semaphore. Returns `true` if the lock operation was successful, `false` otherwise.
    - `bool lock(blocking: false)` will attempt to lock the semaphore without blocking. If the semaphore is already locked, it will return `false`.
    - `bool lock()` or `bool lock(blocking: true)` will _synchronously_ block the thread and wait until the semaphore has been signaled and is available to be locked.

#### **Unlocking**
- `bool unlock()`: Unlocks the semaphore. Returns `true` if the unlock operation was successful, `false` otherwise.

#### **Disposing**
- `bool dispose()`: Disposes of the semaphore. Returns `true` if the dispose operation was successful, `false` otherwise. Internally, if the semaphore is still locked, it will be unlocked before being disposed.

### **Properties**:
- `String identifier`: The unique identifier for the semaphore. Internally this will be prefixed with the platform-specific prefix. i.e. `/` on Unix Systems, and `Global\\` on Windows.
- `bool locked`: Returns `true` if the semaphore is currently locked, `false` otherwise.
- `bool disposed`: Returns `true` if the semaphore has been disposed, `false` otherwise.

--- 

## Native Implementation Details & References

### Unix Implementation
The Unix variant of the `runtime_native_semaphores` package interfaces directly with Unix semaphore APIs via FFI, targeting MacOS (Intel & Apple Silicon) and Linux (x86_64 and Arm64). This implementation harnesses `sem_open` for semaphore creation with flags `O_CREAT` for ensuring creation, setting appropriate mode permissions, and initializing semaphore values. Semaphore locking and unlocking leverage `sem_wait` for blocking waits and `sem_trywait` for non-blocking attempts, respectively. `sem_post` is used to release the semaphore. Critical to resource management, `sem_close` and `sem_unlink` are invoked for closing and unlinking semaphores, mitigating resource leaks. This direct interaction with Unix's semaphore functions enables precise control over synchronization primitives, essential for high-performance, concurrent applications requiring robust inter-process communication. The implementation rigorously validates identifier lengths against `UnixSemLimits.NAME_MAX_CHARACTERS` to adhere to system constraints, ensuring reliable semaphore operations across supported Unix platforms.
The Unix implementation is based on the following [Open Group Base Specifications IEEE reference](https://pubs.opengroup.org/onlinepubs/009695399/basedefs/semaphore.h.html) and the FFI bindings can be found [here](https://github.com/open-runtime/native_semaphores/blob/main/lib/src/ffi/unix.dart).

### Windows Implementation
For Windows, the `runtime_native_semaphores` package's implementation involves direct calls to the Windows API through FFI, catering to semaphore management. It utilizes `CreateSemaphoreW` to instantiate semaphores, with careful consideration of identifier conventions and path lengths, adhering to the `MAX_PATH` constraint defined in `WindowsCreateSemaphoreWMacros`. Identifiers internally standardized with a `Global\\` prefix and checked for invalid characters to ensure compatibility with Windows naming conventions.
Semaphore operations are managed via `WaitForSingleObject` for locking, which accommodates both blocking and non-blocking modes through appropriate timeout settings. Unlocking is achieved with `ReleaseSemaphore`, incrementing the semaphore count by a predefined value. Critical to ensuring the release of system resources, `CloseHandle` is invoked during disposal to close the semaphore handle, followed by memory cleanup for the identifier.
This Windows-specific approach to semaphore handling allows for precise synchronization control in multi-process environments on Windows platforms. The implementation's focus on compliance with Windows standards and error handling ensures robust and reliable semaphore operations, essential for maintaining data integrity and preventing deadlock in concurrent Windows applications.

Additional details on the Windows API can be found [here](https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-createsemaphorew) and the FFI bindings can be found [here](https://github.com/open-runtime/native_semaphores/blob/main/lib/src/ffi/windows.dart).

--- 

## Motivation
The advent of native named semaphores was driven by the critical demand for efficient, reliable inter-process communication (IPC) mechanisms in high-performance software, specifically within the realms of the [DCLI](https://pub.dev/packages/dcli) framework and the [Pieces for Developers | Flutter Desktop App](https://pieces.app). These applications necessitated IPC-safe locks that could guarantee atomic operations across multiple processes and Dart isolates, ensuring data integrity and preventing race conditions. By harnessing native operating system capabilities, native named semaphores offer an unparalleled level of performance and synchronization precision, addressing the complex concurrency challenges these sophisticated applications face. Their development marks a pivotal enhancement in Dart's ecosystem, empowering developers to build more complex, robust, and efficient multi-process applications.

## Contributing
We welcome any and all feedback and contributions to the `runtime_native_semaphores` package. If you encounter any issues, have feature requests, or would like to contribute to the
package, please feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/open-runtime/native_semaphores).

## License
This is an open-source package developed by the team at [Pieces for Developers](https://pieces.app) and is licensed under the [Apache License 2.0](./LICENSE).

