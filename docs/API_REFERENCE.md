
# Utils API Reference

This module provides utility functions for working with the Dart `late` keyword, specifically determining if a late property has been initialized.

## Typedefs

### `LatePropertySetParameterType`
Function type definition for the callback passed to `LatePropertyAssigned`.

```dart
typedef LatePropertySetParameterType = dynamic Function();
```

## Top-Level Functions

### `LatePropertyAssigned<X>`

Evaluates a function to check if a `late` property has been initialized. 

**Note**: This approach relies on error message string matching (`has not been initialized.`) and probably will not work with code obfuscation.

```dart
bool LatePropertyAssigned<X>(LatePropertySetParameterType function)
```

#### Parameters:
- `function`: A callback of type `LatePropertySetParameterType` (`dynamic Function()`) that accesses the `late` property.

#### Return type:
- `bool`: Returns `true` if the property has been assigned, and `false` if the specific `late` initialization error is caught. If a different error is thrown, it is rethrown with its stack trace.

#### Example

```dart
import 'package:native_semaphores/src/utils/late_property_assigned.dart';

class MyClass {
  late String myString;
  
  bool get isMyStringAssigned => 
      LatePropertyAssigned<String>(() => myString);
}

void main() {
  final instance = MyClass();
  
  print(instance.isMyStringAssigned); // false
  
  instance.myString = 'Hello, World!';
  
  print(instance.isMyStringAssigned); // true
}
```

