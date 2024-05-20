// NOTE: This file contains code that has been ported and flattened from original sources copyrighted by Sudipto Chandra
// All original code can be found in the following repository: https://github.com/bitanon/hashlib/blob/2acc229075bc0b4d08ffb9817a5c38b09014fc94/test/xxh64_test.dart
// The main reason this code has been ported is to mitigate version constraints when consuming this library externally
// Nevertheless, a big shout out to Sudipto Chandra for his work on the original library 🙏

// Original Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

// Modifications made by Tsavo van den Berg, Knott @2024

import 'package:runtime_native_semaphores/src/utils/XXHash64.dart' show XXHash64, xxh64;
import 'package:test/test.dart';

const seed = 0x9E3779B1;
const xxh64_1 = XXHash64(seed);
const data = <int>[
  158, 255, 31, 75, 94, 83, 47, 221, 181, 84, 77, 42, 149, 43, 87, 174, 93, //
  186, 116, 233, 211, 166, 76, 152, 48, 96, 192, 128, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
];

void main() {
  group('XXHash64 test', () {
    test('with seed = 0 and an empty string', () {
      expect(xxh64.convert([]).hex(), "ef46db3751d8e999");
    });
    test('with seed = 0 and a single letter', () {
      expect(xxh64.convert([data[0]]).hex(), "4fce394cc88952d8");
    });
    test('with seed = 0 and 14 letters', () {
      expect(xxh64.convert(data.take(14).toList()).hex(), "cffa8db881bc3a3d");
    });
    test('with seed = 0 and 101 letters', () {
      expect(xxh64.convert(data).hex(), "0eab543384f878ad");
    });

    test('with seed = $seed and an empty string', () {
      expect(xxh64_1.convert([]).hex(), "ac75fda2929b17ef");
    });

    test('with seed = $seed and a single letter', () {
      expect(xxh64_1.convert([data[0]]).hex(), "739840cb819fa723");
    });

    test('with seed = $seed and 14 letters', () {
      expect(xxh64_1.convert(data.take(14).toList()).hex(), "5b9611585efcc9cb");
    });

    test('with seed = $seed and 101 letters', () {
      expect(xxh64_1.convert(data).hex(), "caa65939306f1e21");
    });
  });
}