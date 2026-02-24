# Utils Module Quickstart

## 1. Overview
The Utils module provides internal utilities to assist with common Dart programming patterns within the native semaphores library. Currently, it includes a helpful utility to determine whether a `late` property has been initialized without crashing the application.

## 2. Import
To use the utilities in your project, import the specific file:

```dart
import 'package:runtime_native_semaphores/src/utils/late_property_assigned.dart';
```

## 3. Setup
The Utils module consists of standalone functions and typedefs, so there is no setup, initialization, or configuration required. You can simply import the file and use the provided functions directly.

## 4. Types and Definitions

### `LatePropertySetParameterType`
This typedef defines the signature of the closure passed to `LatePropertyAssigned`:
```dart
typedef LatePropertySetParameterType = dynamic Function();
```

### `LatePropertyAssigned<X>`
The generic function that safely evaluates if a `late` property has been assigned:
```dart
bool LatePropertyAssigned<X>(LatePropertySetParameterType function)
```

## 5. Common Operations

### Checking if a `late` property is initialized

You can use the `LatePropertyAssigned<X>` function to check if a `late` variable of type `X` has been assigned a value. Pass a closure that accesses the variable.

```dart
import 'package:runtime_native_semaphores/src/utils/late_property_assigned.dart';

class MyClass {
  late String myLateString;

  void checkInitialization() {
    // Before initialization
    bool isAssigned = LatePropertyAssigned<String>(() => myLateString);
    print('Is myLateString assigned? $isAssigned'); // false

    // Initialize the variable
    myLateString = 'Hello, Semaphores!';

    // After initialization
    isAssigned = LatePropertyAssigned<String>(() => myLateString);
    print('Is myLateString assigned? $isAssigned'); // true
  }
}
```

## 6. Configuration & Limitations
**Important Note on Code Obfuscation:** 
The `LatePropertyAssigned` function relies on catching the exception thrown by Dart upon accessing an uninitialized `late` variable and checking its string representation for the text `'has not been initialized.'`. Due to this implementation detail, **this function will likely not work as expected if your Dart code is obfuscated**. Keep this in mind when compiling for production environments.
