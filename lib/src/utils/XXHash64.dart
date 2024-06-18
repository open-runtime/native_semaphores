// NOTE: This file contains code that has been ported and flattened from original sources copyrighted by Sudipto Chandra
// All original code can be found in these two repositories: https://github.com/bitanon/hashlib and https://github.com/bitanon/hashlib_codecs
// The main reason this code has been ported is to mitigate version constraints when consuming this library externally

// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

// Modifications made by Tsavo van den Berg, Knott @2024

import 'dart:typed_data' show ByteBuffer, ByteData, Endian, TypedData, Uint32List, Uint64List, Uint8List;
import 'dart:convert' show AsciiDecoder, AsciiEncoder, Codec, Converter, Encoding, JsonDecoder, JsonEncoder, Utf8Decoder, Utf8Encoder, latin1;
import 'dart:async' show Future, Stream, StreamTransformer;
import 'dart:io' show File;

const int _zero = 0x30;
const int _bigA = 0x41;
const int _smallA = 0x61;

// ========================================================
// Base-8 Encoder and Decoder
// ========================================================

class _Base8Encoder extends ByteEncoder {
  const _Base8Encoder() : super(bits: 3);

  @override
  Iterable<int> convert(Iterable<int> input) {
    return super.convert(input).map((y) => y + _zero);
  }
}

class _Base8Decoder extends ByteDecoder {
  const _Base8Decoder() : super(bits: 3);

  @override
  Iterable<int> convert(Iterable<int> input) {
    int x;
    return super.convert(input.map((y) {
      x = y - _zero;
      if (x < 0 || x > 7) {
        throw FormatException('Invalid character $y');
      }
      return x;
    }));
  }
}

// ========================================================
// Base-8 Codec
// ========================================================

class Base8Codec extends HashlibCodec {
  @override
  final ByteEncoder encoder;

  @override
  final ByteDecoder decoder;

  const Base8Codec._({
    required this.encoder,
    required this.decoder,
  });

  /// Codec instance to encode and decode 8-bit integer sequence to 3-bit
  /// Base-8 or Octal character sequence using the alphabet:
  /// ```
  /// 012345678
  /// ```
  static const Base8Codec standard = Base8Codec._(
    encoder: _Base8Encoder(),
    decoder: _Base8Decoder(),
  );
}

/// Converts 8-bit integer sequence to 3-bit Base-8 character sequence.
///
/// Parameters:
/// - [input] is a sequence of 8-bit integers.
/// - [codec] is the [Base8Codec] to use. Default: [Base8Codec.standard].
///
/// **NOTE:**, This implementation is a bit-wise encoding of the input bytes.
/// To get the numeric representation of the [input] in binary:
/// ```dart
/// toBigInt(input).toRadixString(8)
/// ```
String toOctal(
    Iterable<int> input, {
      Base8Codec codec = Base8Codec.standard,
    }) {
  var out = codec.encoder.convert(input);
  return String.fromCharCodes(out);
}

/// Converts 3-bit Base-8 character sequence to 8-bit integer sequence.
///
/// Parameters:
/// - [input] should be a valid octal/base-8 encoded string.
/// - [codec] is the [Base8Codec] to use. Default: [Base8Codec.standard].
///
/// Throws:
/// - [FormatException] if the [input] contains invalid characters.
///
/// If a partial string is detected, the following bits are assumed to be zeros.
///
/// **NOTE:**, This implementation is a bit-wise decoding of the input bytes.
/// To get the bytes from the numeric representation of the [input]:
/// ```dart
/// fromBigInt(BigInt.parse(input, radix: 8));
/// ```
Uint8List fromOctal(
    String input, {
      Base8Codec codec = Base8Codec.standard,
    }) {
  var out = codec.decoder.convert(input.codeUnits);
  return Uint8List.fromList(out.toList());
}

// ========================================================
// Base-2 Converters
// ========================================================

class _Base2Encoder extends ByteEncoder {
  const _Base2Encoder() : super(bits: 2);

  @override
  Iterable<int> convert(Iterable<int> input) sync* {
    for (int x in input) {
      yield _zero + ((x >>> 7) & 1);
      yield _zero + ((x >>> 6) & 1);
      yield _zero + ((x >>> 5) & 1);
      yield _zero + ((x >>> 4) & 1);
      yield _zero + ((x >>> 3) & 1);
      yield _zero + ((x >>> 2) & 1);
      yield _zero + ((x >>> 1) & 1);
      yield _zero + ((x) & 1);
    }
  }
}

class _Base2Decoder extends ByteDecoder {
  const _Base2Decoder() : super(bits: 2);

  @override
  Iterable<int> convert(Iterable<int> input) sync* {
    int p, n, x, y;
    p = n = 0;
    for (y in input) {
      x = y - _zero;
      if (x != 0 && x != 1) {
        throw FormatException('Invalid character $y');
      }
      if (n < 8) {
        p = (p << 1) | x;
        n++;
      } else {
        yield p;
        n = 1;
        p = x;
      }
    }
    if (n > 0) {
      yield p;
    }
  }
}

// ========================================================
// Base-2 Codec
// ========================================================

class Base2Codec extends HashlibCodec {
  @override
  final encoder = const _Base2Encoder();

  @override
  final decoder = const _Base2Decoder();

  const Base2Codec._();

  /// Codec instance to encode and decode 8-bit integer sequence to 2-bit
  /// Base-2 or Binary character sequence using the alphabet:
  /// ```
  /// 01
  /// ```
  static const Base2Codec standard = Base2Codec._();
}

/// Converts 8-bit integer sequence to 2-bit Base-2 character sequence.
///
/// Parameters:
/// - [input] is a sequence of 8-bit integers.
/// - [codec] is the [Base2Codec] to use. Default: [Base2Codec.standard].
///
/// **NOTE:**, This implementation is a bit-wise encoding of the input bytes.
/// To get the numeric representation of the [input] in binary:
/// ```dart
/// toBigInt(input).toRadixString(2)
/// ```
String toBinary(
    Iterable<int> input, {
      Base2Codec codec = Base2Codec.standard,
    }) {
  var out = codec.encoder.convert(input);
  return String.fromCharCodes(out);
}

/// Converts 2-bit Base-2 character sequence to 8-bit integer sequence.
///
/// Parameters:
/// - [input] should be a valid binary/base-2 encoded string.
/// - [codec] is the [Base2Codec] to use. Default: [Base2Codec.standard].
///
/// Throws:
/// - [FormatException] if the [input] contains invalid characters.
///
/// If a partial string is detected, the following bits are assumed to be zeros.
///
/// **NOTE:**, This implementation is a bit-wise decoding of the input bytes.
/// To get the bytes from the numeric representation of the [input]:
/// ```dart
/// fromBigInt(BigInt.parse(input, radix: 2));
/// ```
Uint8List fromBinary(
    String input, {
      Base2Codec codec = Base2Codec.standard,
    }) {
  var out = codec.decoder.convert(input.codeUnits);
  return Uint8List.fromList(out.toList());
}

abstract class BitEncoder extends HashlibConverter {
  /// Creates a new [BitEncoder] instance.
  const BitEncoder();

  /// Converts [input] array of numbers with bit-length of [source] to an array
  /// of numbers with bit-length of [target]. The [input] array will be treated
  /// as a sequence of bits to convert.
  ///
  /// After consuming all of input sequence, if there are some non-zero partial
  /// word remains, 0 will be padded on the right to make the final word.
  @override
  Iterable<int> convert(Iterable<int> input) sync* {
    if (source < 2 || source > 64) {
      throw ArgumentError('The source bit length should be between 2 to 64');
    }
    if (target < 2 || target > 64) {
      throw ArgumentError('The target bit length should be between 2 to 64');
    }

    int x, p, n, s, t;
    p = n = t = 0;
    s = 1 << (source - 1);
    s = s ^ (s - 1);

    // generate words from the input bits
    for (x in input) {
      p = (p << source) ^ (x & s);
      t = (t << source) ^ s;
      n += source;
      while (n >= target) {
        n -= target;
        yield p >>> n;
        t >>>= target;
        p &= t;
      }
    }

    // n > 0 means that there is a partial word remaining.
    if (n > 0) {
      // pad the word with 0 on the right to make the final word
      yield p << (target - n);
    }
  }
}

abstract class BitDecoder extends HashlibConverter {
  /// Creates a new [BitDecoder] instance.
  const BitDecoder();

  /// Converts [encoded] array of numbers with bit-length of [source] to an array
  /// of numbers with bit-length of [target]. The [encoded] array will be treated
  /// as a sequence of bits to convert.
  ///
  /// If the [encoded] array contains negative numbers or numbers having more than
  /// the [source] bits, it will be treated as the end of the input sequence.
  ///
  /// After consuming all of input sequence, if there are some non-zero partial
  /// word remains, it will throw [FormatException].
  @override
  Iterable<int> convert(Iterable<int> encoded) sync* {
    if (source < 2 || source > 64) {
      throw ArgumentError('The source bit length should be between 2 to 64');
    }
    if (target < 2 || target > 64) {
      throw ArgumentError('The target bit length should be between 2 to 64');
    }

    int x, p, n, s, t;
    p = n = t = 0;
    s = 1 << (source - 1);
    s = s ^ (s - 1);

    // generate words from the input bits
    for (x in encoded) {
      if (x < 0 || x > s) break;
      p = (p << source) ^ x;
      t = (t << source) ^ s;
      n += source;
      while (n >= target) {
        n -= target;
        yield p >>> n;
        t >>>= target;
        p &= t;
      }
    }

    // p > 0 means that there is a non-zero partial word remaining
    if (p > 0) {
      throw FormatException('Invalid length');
    }
  }
}

/// Base class for encoding from and to 8-bit integer sequence
abstract class HashlibCodec extends Codec<Iterable<int>, Iterable<int>> {
  /// Creates a new [HashlibCodec] instance.
  const HashlibCodec();

  @override
  BitEncoder get encoder;

  @override
  BitDecoder get decoder;

  /// Encodes an [input] string using this codec
  @pragma('vm:prefer-inline')
  Iterable<int> encodeString(String input) => encode(input.codeUnits);

  /// Decodes an [encoded] string using this codec
  @pragma('vm:prefer-inline')
  Iterable<int> decodeString(String encoded) => decode(encoded.codeUnits);

  /// Encodes an [input] buffer using this codec
  @pragma('vm:prefer-inline')
  Iterable<int> encodeBuffer(ByteBuffer input) => encode(input.asUint8List());

  /// Decodess an [encoded] buffer using this codec
  @pragma('vm:prefer-inline')
  Iterable<int> decodeBuffer(ByteBuffer encoded) =>
      decode(encoded.asUint8List());
}

/// Base class for bit-wise encoder and decoder implementation
abstract class HashlibConverter
    extends Converter<Iterable<int>, Iterable<int>> {
  /// Creates a new [HashlibConverter] instance.
  const HashlibConverter();

  /// The bit-length of the input array elements.
  /// The value should be between 2 to 64.
  int get source;

  /// The bit-length of the output array elements.
  /// The value should be between 2 to 64.
  int get target;

  /// Converts [input] array of numbers with bit-length of [source] to an array
  /// of numbers with bit-length of [target]. The [input] array will be treated
  /// as a sequence of bits to convert.
  @override
  Iterable<int> convert(Iterable<int> input);
}

class ByteEncoder extends BitEncoder {
  final int bits;

  @override
  final int source = 8;

  /// Creates a new [ByteEncoder] instance.
  ///
  /// Parameters:
  /// - [bits] is bit-length of a single word in the output
  const ByteEncoder({
    required this.bits,
  });

  @override
  int get target => bits;
}

class ByteDecoder extends BitDecoder {
  final int bits;

  @override
  final int target = 8;

  /// Creates a new [ByteDecoder] instance.
  ///
  /// Parameters:
  /// - [bits] is bit-length of a single word in the output
  const ByteDecoder({
    required this.bits,
  });

  @override
  int get source => bits;
}

// ========================================================
// Base-16 Encoder and Decoder
// ========================================================

class _Base16Encoder extends ByteEncoder {
  final int startCode;

  const _Base16Encoder._(this.startCode) : super(bits: 4);

  static const upper = _Base16Encoder._(_bigA - 10);
  static const lower = _Base16Encoder._(_smallA - 10);

  @override
  Iterable<int> convert(Iterable<int> input) sync* {
    int a, b;
    for (int x in input) {
      a = (x >>> 4) & 0xF;
      b = x & 0xF;
      a += a < 10 ? _zero : startCode;
      b += b < 10 ? _zero : startCode;
      yield a;
      yield b;
    }
  }
}

class _Base16Decoder extends ByteDecoder {
  const _Base16Decoder() : super(bits: 4);

  @override
  Iterable<int> convert(Iterable<int> input) sync* {
    bool t;
    int p, x, y;
    p = 0;
    t = false;
    for (y in input) {
      if (y >= _smallA) {
        x = y - _smallA + 10;
      } else if (y >= _bigA) {
        x = y - _bigA + 10;
      } else if (y >= _zero) {
        x = y - _zero;
      } else {
        x = -1;
      }
      if (x < 0 || x > 15) {
        throw FormatException('Invalid character $y');
      }
      if (t) {
        yield ((p << 4) | x);
        p = 0;
        t = false;
      } else {
        p = x;
        t = true;
      }
    }
    if (t) {
      yield p;
    }
  }
}

// ========================================================
// Base-16 Codec
// ========================================================

class Base16Codec extends HashlibCodec {
  @override
  final ByteEncoder encoder;

  @override
  final ByteDecoder decoder;

  const Base16Codec._({
    required this.encoder,
    required this.decoder,
  });

  /// Codec instance to encode and decode 8-bit integer sequence to 4-bit
  /// Base-16 or Hexadecimal character sequence using the alphabet:
  /// ```
  /// 0123456789ABCDEF
  /// ```
  static const Base16Codec upper = Base16Codec._(
    encoder: _Base16Encoder.upper,
    decoder: _Base16Decoder(),
  );

  /// Codec instance to encode and decode 8-bit integer sequence to 4-bit
  /// Base-16 or Hexadecimal character sequence using the alphabet:
  /// ```
  /// 0123456789abcdef
  /// ```
  static const Base16Codec lower = Base16Codec._(
    encoder: _Base16Encoder.lower,
    decoder: _Base16Decoder(),
  );
}

Base16Codec _codecFromParameters({
  bool upper = false,
}) {
  if (upper) {
    return Base16Codec.upper;
  } else {
    return Base16Codec.lower;
  }
}

/// Converts 8-bit integer sequence to 4-bit Base-16 character sequence.
///
/// Parameters:
/// - [input] is a sequence of 8-bit integers.
/// - If [upper] is true, the uppercase standard alphabet is used.
/// - [codec] is the [Base16Codec] to use. It is derived from the other
///   parameters if not provided.
String toHex(
    Iterable<int> input, {
      Base16Codec? codec,
      bool upper = false,
    }) {
  codec ??= _codecFromParameters(upper: upper);
  var out = codec.encoder.convert(input);
  return String.fromCharCodes(out);
}

/// Converts 4-bit Base-16 character sequence to 8-bit integer sequence.
///
/// Parameters:
/// - [input] should be a valid Base-16 (hexadecimal) string.
/// - [codec] is the [Base16Codec] to use. It is derived from the other
///   parameters if not provided.
///
/// Throws:
/// - [FormatException] if the [input] contains invalid characters.
///
/// This implementation can handle both uppercase and lowercase alphabets. If a
/// partial string is detected, the following bits are assumed to be zeros.
Uint8List fromHex(
    String input, {
      Base16Codec? codec,
    }) {
  codec ??= _codecFromParameters();
  var out = codec.decoder.convert(input.codeUnits);
  return Uint8List.fromList(out.toList());
}

BigIntCodec _bigIntCodecFromParameters({
  bool msbFirst = false,
}) {
  if (msbFirst) {
    return BigIntCodec.msbFirst;
  } else {
    return BigIntCodec.lsbFirst;
  }
}

/// Converts 8-bit integer sequence to [BigInt].
///
/// Parameters:
/// - [input] is a sequence of 8-bit integers.
/// - If [msbFirst] is true, [input] bytes are read in big-endian order giving
///   the first byte the most significant value, otherwise the bytes are read as
///   little-endian order, giving the first byte the least significant value.
/// - [codec] is the [BigIntCodec] to use. It is derived from the other
///   parameters if not provided.
///
/// Throws:
/// - [FormatException] when the [input] is empty.
BigInt toBigInt(
    Iterable<int> input, {
      BigIntCodec? codec,
      bool msbFirst = false,
    }) {
  codec ??= _bigIntCodecFromParameters(msbFirst: msbFirst);
  return codec.encoder.convert(input);
}

/// Converts a [BigInt] to 8-bit integer sequence.
///
/// Parameters:
/// - [input] is a non-negative [BigInt].
/// - If [msbFirst] is true, [input] bytes are read in big-endian order giving
///   the first byte the most significant value, otherwise the bytes are read as
///   little-endian order, giving the first byte the least significant value.
/// - [codec] is the [BigIntCodec] to use. It is derived from the other
///   parameters if not provided.
///
/// Raises:
/// - [FormatException] when the [input] is negative.
Uint8List fromBigInt(
    BigInt input, {
      BigIntCodec? codec,
      bool msbFirst = false,
    }) {
  codec ??= _bigIntCodecFromParameters(msbFirst: msbFirst);
  var out = codec.decoder.convert(input);
  return Uint8List.fromList(out.toList());
}

typedef BigIntEncoder = Converter<Iterable<int>, BigInt>;
typedef BigIntDecoder = Converter<BigInt, Iterable<int>>;

// ========================================================
// LSB First Encoder and Decoder
// ========================================================

class _BigIntLSBFirstEncoder extends BigIntEncoder {
  const _BigIntLSBFirstEncoder();

  @override
  BigInt convert(Iterable<int> input) {
    int a, b, i, j;
    var out = <int>[];
    for (int x in input) {
      a = (x >>> 4) & 0xF;
      b = x & 0xF;
      a += a < 10 ? _zero : _smallA - 10;
      b += b < 10 ? _zero : _smallA - 10;
      out.add(b);
      out.add(a);
    }
    if (out.isEmpty) {
      throw FormatException('Empty input');
    }
    for (j = out.length - 1; j > 0; j--) {
      if (out[j] != _zero) break;
    }
    var hex = out.take(j + 1);
    for (i = 0; i < j; i++, j--) {
      a = out[i];
      out[i] = out[j];
      out[j] = a;
    }
    return BigInt.parse(String.fromCharCodes(hex), radix: 16);
  }
}

class _BigIntLSBFirstDecoder extends BigIntDecoder {
  const _BigIntLSBFirstDecoder();

  @override
  Iterable<int> convert(BigInt input) sync* {
    if (input.isNegative) {
      throw FormatException('Negative numbers are not supported');
    }
    if (input == BigInt.zero) {
      yield 0;
      return;
    }
    int i, a, b;
    var bytes = input.toRadixString(16).codeUnits;
    for (i = bytes.length - 2; i >= 0; i -= 2) {
      a = bytes[i];
      b = bytes[i + 1];
      a -= a < _smallA ? _zero : _smallA - 10;
      b -= b < _smallA ? _zero : _smallA - 10;
      yield (a << 4) | b;
    }
    if (i == -1) {
      a = bytes[0];
      a -= a < _smallA ? _zero : _smallA - 10;
      yield a;
    }
  }
}

// ========================================================
// MSB First Encoder and Decoder
// ========================================================

class _BigIntMSBFirstEncoder extends BigIntEncoder {
  const _BigIntMSBFirstEncoder();

  @override
  BigInt convert(Iterable<int> input) {
    int a, b;
    var out = <int>[];
    for (int x in input) {
      a = (x >>> 4) & 0xF;
      b = x & 0xF;
      a += a < 10 ? _zero : _smallA - 10;
      b += b < 10 ? _zero : _smallA - 10;
      out.add(a);
      out.add(b);
    }
    if (out.isEmpty) {
      throw FormatException('Empty input');
    }
    return BigInt.parse(String.fromCharCodes(out), radix: 16);
  }
}

class _BigIntMSBFirstDecoder extends BigIntDecoder {
  const _BigIntMSBFirstDecoder();

  @override
  Iterable<int> convert(BigInt input) sync* {
    if (input.isNegative) {
      throw FormatException('Negative numbers are not supported');
    }
    if (input == BigInt.zero) {
      yield 0;
      return;
    }
    int i, a, b, n;
    var bytes = input.toRadixString(16).codeUnits;
    n = bytes.length;
    i = 1;
    if (n & 1 == 1) {
      a = bytes[0];
      a -= a < _smallA ? _zero : _smallA - 10;
      yield a;
      i++;
    }
    for (; i < n; i += 2) {
      a = bytes[i - 1];
      b = bytes[i];
      a -= a < _smallA ? _zero : _smallA - 10;
      b -= b < _smallA ? _zero : _smallA - 10;
      yield (a << 4) | b;
    }
  }
}

// ========================================================
// BigInt Codec
// ========================================================


class Ascii {
  static final _encoder = AsciiEncoder();
  static final _decoder = AsciiDecoder();

  static final String Function(List<int> bytes, [int start, int? end]) decode  = _decoder.convert;

  static final List<int> Function(String string) encode = _encoder.convert;
}

class Utf8 {
  static final _encoder = Utf8Encoder();
  static final _decoder = Utf8Decoder();

  static final String Function(List<int> bytes, [int start, int? end]) decode  = _decoder.convert;

  static final List<int> Function(String string) encode = _encoder.convert;
}

class JSON {
  static final _encoder = JsonEncoder();
  static final _decoder = JsonDecoder();

  static final String Function(Object object) encode = _encoder.convert;

  static final Function(String input) decode = _decoder.convert;
}

class BigIntCodec extends Codec<Iterable<int>, BigInt> {
  @override
  final BigIntEncoder encoder;

  @override
  final BigIntDecoder decoder;

  const BigIntCodec._({
    required this.encoder,
    required this.decoder,
  });

  /// Codec instance to encode and decode 8-bit integer sequence to [BigInt]
  /// number treating the input bytes in big-endian order.
  static const BigIntCodec msbFirst = BigIntCodec._(
    encoder: _BigIntMSBFirstEncoder(),
    decoder: _BigIntMSBFirstDecoder(),
  );

  /// Codec instance to encode and decode 8-bit integer sequence to [BigInt]
  /// number treating the input bytes in little-endian order.
  static const BigIntCodec lsbFirst = BigIntCodec._(
    encoder: _BigIntLSBFirstEncoder(),
    decoder: _BigIntLSBFirstDecoder(),
  );
}

class HashDigest extends Object {
  final Uint8List bytes;

  const HashDigest(this.bytes);

  /// Returns the byte buffer associated with this digest.
  ByteBuffer get buffer => bytes.buffer;

  /// The message digest as a string of hexadecimal digits.
  @override
  String toString() => hex();

  /// The message digest as a binary string.
  String binary() => toBinary(bytes);

  /// The message digest as a octal string.
  String octal() => toOctal(bytes);

  /// The message digest as a hexadecimal string.
  ///
  /// Parameters:
  /// - If [upper] is true, the string will be in uppercase alphabets.
  String hex([bool upper = false]) => toHex(bytes, upper: upper);


  /// The message digest as a BigInt.
  ///
  /// If [endian] is [Endian.little], it will treat the digest bytes as a little
  /// endian number; Otherwise, if [endian] is [Endian.big], it will treat the
  /// digest bytes as a big endian number.
  BigInt bigInt({Endian endian = Endian.little}) =>
      toBigInt(bytes, msbFirst: endian == Endian.big);

  /// Gets 64-bit unsiged integer from the message digest.
  ///
  /// If [endian] is [Endian.little], it will treat the digest bytes as a little
  /// endian number; Otherwise, if [endian] is [Endian.big], it will treat the
  /// digest bytes as a big endian number.
  int number([Endian endian = Endian.big]) =>
      toBigInt(bytes, msbFirst: endian == Endian.big).toUnsigned(64).toInt();

  /// The message digest as a string of ASCII alphabets.
  String ascii() => Ascii.decode(bytes);

  /// The message digest as a string of UTF-8 alphabets.
  String utf8() => Utf8.decode(bytes);

  /// Returns the digest in the given [encoding]
  String to(Encoding encoding) => encoding.decode(bytes);

  @override
  int get hashCode => bytes.hashCode;

  @override
  bool operator ==(other) => isEqual(other);

  /// Checks if the message digest equals to [other].
  ///
  /// Here, the [other] can be a one of the following:
  /// - Another [HashDigest] object.
  /// - An [Iterable] containing an array of bytes
  /// - Any [ByteBuffer] or [TypedData] that will be converted to [Uint8List]
  /// - A [String], which will be treated as a hexadecimal encoded byte array
  ///
  /// This function will return True if all bytes in the [other] matches with
  /// the [bytes] of this object. If the length does not match, or the type of
  /// [other] is not supported, it returns False immediately.
  bool isEqual(other) {
    if (other is HashDigest) {
      return isEqual(other.bytes);
    } else if (other is ByteBuffer) {
      return isEqual(buffer.asUint8List());
    } else if (other is TypedData && other is! Uint8List) {
      return isEqual(other.buffer.asUint8List());
    } else if (other is String) {
      return isEqual(fromHex(other));
    } else if (other is Iterable<int>) {
      if (other is List<int>) {
        if (other.length != bytes.length) {
          return false;
        }
      }
      int i = 0;
      for (int x in other) {
        if (i >= bytes.length || x != bytes[i++]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

/// This sink allows adding arbitrary length byte arrays
/// and produces a [HashDigest] on [close].
abstract class HashDigestSink implements Sink<List<int>> {
  const HashDigestSink();

  /// Returns true if the sink is closed, false otherwise
  bool get closed;

  /// The length of generated hash in bytes
  int get hashLength;

  /// Adds [data] to the message-digest.
  ///
  /// Throws [StateError], if it is called after closing the digest.
  @override
  void add(List<int> data, [int start = 0, int? end]);

  /// Finalizes the message-digest. It calls [digest] method internally.
  @override
  @pragma('vm:prefer-inline')
  void close() => digest();

  /// Finalizes the message-digest and returns a [HashDigest]
  HashDigest digest();

  /// Resets the current state to start from fresh state
  void reset();
}

/// The base class used by the hash algorithm implementations. It implements
/// the [StreamTransformer] and exposes few convenient methods to handle any
/// types of data source.
abstract class HashBase implements StreamTransformer<List<int>, HashDigest> {
  const HashBase();

  /// The name of this algorithm
  String get name;

  /// Create a [HashDigestSink] for generating message-digests
  @pragma('vm:prefer-inline')
  HashDigestSink createSink();

  /// Transforms the byte array input stream to generate a new stream
  /// which contains a single [HashDigest]
  ///
  /// The expected behavior of this method is described below:
  ///
  /// - When the returned stream has a subscriber (calling [Stream.listen]),
  ///   the message-digest generation begins from the input [stream].
  /// - If the returned stream is paused, the processing of the input [stream]
  ///   is also paused, and on resume, it continue processing from where it was
  ///   left off.
  /// - If the returned stream is cancelled, the subscription to the input
  ///   [stream] is also cancelled.
  /// - When the input [stream] is closed, the returned stream also gets closed
  ///   with a [HashDigest] data. The returned stream may produce only one
  ///   such data event in its life-time.
  /// - On error reading the input [stream], or while processing the message
  ///   digest, the subscription to input [stream] cancels immediately and the
  ///   returned stream closes with an error event.
  @override
  Stream<HashDigest> bind(Stream<List<int>> stream) async* {
    var sink = createSink();
    await for (var x in stream) {
      sink.add(x);
    }
    yield sink.digest();
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, HashDigest, RS, RT>(this);

  /// Process the byte array [input] and returns a [HashDigest].
  @pragma('vm:prefer-inline')
  HashDigest convert(List<int> input) {
    var sink = createSink();
    sink.add(input);
    return sink.digest();
  }

  /// Process the [input] string and returns a [HashDigest].
  ///
  /// If the [encoding] is not specified, `codeUnits` are used as input bytes.
  HashDigest string(String input, [Encoding? encoding]) {
    var sink = createSink();
    if (encoding != null) {
      var data = encoding.encode(input);
      sink.add(data);
    } else {
      sink.add(input.codeUnits);
    }
    return sink.digest();
  }

  /// Consumes the entire [stream] of byte array and generates a [HashDigest].
  @pragma('vm:prefer-inline')
  Future<HashDigest> consume(Stream<List<int>> stream) {
    return bind(stream).first;
  }

  /// Consumes the entire [stream] of string and generates a [HashDigest].
  ///
  /// Default [encoding] scheme to get the input bytes is [latin1].
  @pragma('vm:prefer-inline')
  Future<HashDigest> consumeAs(
      Stream<String> stream, [
        Encoding encoding = latin1,
      ]) {
    return bind(stream.transform(encoding.encoder)).first;
  }

  /// Converts the [input] file and returns a [HashDigest] asynchronously.
  ///
  /// If [start] is present, the file will be read from byte-offset [start].
  /// Otherwise from the beginning (index 0).
  ///
  /// If [end] is present, only bytes up to byte-index [end] will be read.
  /// Otherwise, until end of file.
  @pragma('vm:prefer-inline')
  Future<HashDigest> file(File input, [int start = 0, int? end]) {
    return bind(input.openRead(start, end)).first;
  }

  /// Converts the [input] file and returns a [HashDigest] synchronously.
  ///
  /// If [start] is present, the file will be read from byte-offset [start].
  /// Otherwise from the beginning (index 0).
  ///
  /// If [end] is present, only bytes up to byte-index [end] will be read.
  /// Otherwise, until end of file.
  ///
  /// If [bufferSize] is present, the file will be read in chunks of this size.
  /// By default the [bufferSize] is `2048`.
  HashDigest fileSync(
      File input, {
        int start = 0,
        int? end,
        int bufferSize = 2048,
      }) {
    var raf = input.openSync();
    try {
      var sink = createSink();
      var buffer = Uint8List(bufferSize);
      int length = end ?? raf.lengthSync();
      for (int i = start, l; i < length; i += l) {
        l = raf.readIntoSync(buffer);
        sink.add(buffer, 0, l);
      }
      return sink.digest();
    } finally {
      raf.closeSync();
    }
  }
}

// Maximum length of message allowed (considering both the JS and Dart VM)
const int _maxMessageLength = 0x3FFFFFFFFFFFF; // (1 << 50) - 1

abstract class BlockHashBase extends HashBase {
  const BlockHashBase();

  @override
  BlockHashSink createSink();
}

abstract class BlockHashSink implements HashDigestSink {
  /// The flag tracking if the [digest] is called once.
  bool _closed = false;

  /// The message digest (available after the [digest] call)
  HashDigest? _digest;

  /// The current position of data in the [buffer]
  int pos = 0;

  /// The message length in bytes
  int messageLength = 0;

  /// The internal block length of the algorithm in bytes
  final int blockLength;

  /// The main buffer
  late final Uint8List buffer;

  /// The [buffer] as Uint32List
  late final Uint32List sbuffer;

  /// The [buffer] as ByteData
  late final ByteData bdata;

  /// Initialize a new sink for the block hash
  ///
  /// Parameters:
  /// - [blockLength] is the length of each block in each [$update] call.
  /// - [bufferLength] is the buffer length where blocks are stored temporarily
  BlockHashSink(this.blockLength, {int? bufferLength}) : super() {
    buffer = Uint8List(bufferLength ?? blockLength);
    sbuffer = buffer.buffer.asUint32List();
    bdata = buffer.buffer.asByteData();
  }

  @override
  bool get closed => _closed;

  /// Get the message length in bits
  int get messageLengthInBits => messageLength << 3;

  /// Internal method to update the message-digest with a single [block].
  ///
  /// The method starts reading the block from [offset] index
  void $update(List<int> block, [int offset = 0, bool last = false]);

  /// Finalizes the message digest with the remaining message block,
  /// and returns the output as byte array.
  Uint8List $finalize();

  @override
  void reset() {
    pos = 0;
    messageLength = 0;
    _digest = null;
    _closed = false;
  }

  @override
  void add(List<int> data, [int start = 0, int? end]) {
    if (_closed) {
      throw StateError('The message-digest is already closed');
    }

    end ??= data.length;
    if (messageLength - start > _maxMessageLength - end) {
      throw StateError('Exceeds the maximum message size limit');
    }

    $process(data, start, end);
  }

  /// Processes a chunk of input data
  void $process(List<int> chunk, int start, int end) {
    int t = start;
    if (pos > 0) {
      for (; t < end && pos < blockLength; pos++, t++) {
        buffer[pos] = chunk[t];
      }
      messageLength += t - start;
      if (pos < blockLength) return;

      $update(buffer);
      pos = 0;
    }

    while ((end - t) >= blockLength) {
      messageLength += blockLength;
      $update(chunk, t);
      t += blockLength;
    }

    messageLength += end - t;
    for (; t < end; pos++, t++) {
      buffer[pos] = chunk[t];
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void close() => digest();

  @override
  HashDigest digest() {
    if (_closed) return _digest!;
    _closed = true;
    _digest = HashDigest($finalize());
    return _digest!;
  }
}

/// This implementation is derived from
/// https://github.com/easyaspi314/xxhash-clean/blob/master/xxhash64-ref.c
class XXHash64Sink extends BlockHashSink {
  final int seed;

  @override
  final int hashLength = 8;

  static const int prime64_1 = 0x9E3779B185EBCA87;
  static const int prime64_2 = 0xC2B2AE3D27D4EB4F;
  static const int prime64_3 = 0x165667B19E3779F9;
  static const int prime64_4 = 0x85EBCA77C2B2AE63;
  static const int prime64_5 = 0x27D4EB2F165667C5;

  int _acc1 = 0;
  int _acc2 = 0;
  int _acc3 = 0;
  int _acc4 = 0;

  late final Uint64List qbuffer = buffer.buffer.asUint64List();

  XXHash64Sink(this.seed) : super(32) {
    reset();
  }

  @override
  void reset() {
    super.reset();
    _acc1 = seed + prime64_1 + prime64_2;
    _acc2 = seed + prime64_2;
    _acc3 = seed + 0;
    _acc4 = seed - prime64_1;
  }

  @override
  void $process(List<int> chunk, int start, int end) {
    messageLength += end - start;
    for (; start < end; start++, pos++) {
      if (pos == blockLength) {
        $update();
        pos = 0;
      }
      buffer[pos] = chunk[start];
    }
    if (pos == blockLength) {
      $update();
      pos = 0;
    }
  }

  @pragma('vm:prefer-inline')
  static int _rotl(int x, int n) => (x << n) | (x >>> (64 - n));

  @pragma('vm:prefer-inline')
  static int _accumulate(int x, int y) =>
      _rotl((x + y * prime64_2), 31) * prime64_1;

  @override
  void $update([List<int>? block, int offset = 0, bool last = false]) {
    _acc1 = _accumulate(_acc1, qbuffer[0]);
    _acc2 = _accumulate(_acc2, qbuffer[1]);
    _acc3 = _accumulate(_acc3, qbuffer[2]);
    _acc4 = _accumulate(_acc4, qbuffer[3]);
  }

  @pragma('vm:prefer-inline')
  static int _merge(int h, int a) =>
      (h ^ _accumulate(0, a)) * prime64_1 + prime64_4;

  @override
  Uint8List $finalize() {
    int i, t;
    int hash;

    if (messageLength < 32) {
      hash = seed + prime64_5;
    } else {
      // accumulate
      hash = _rotl(_acc1, 1);
      hash += _rotl(_acc2, 7);
      hash += _rotl(_acc3, 12);
      hash += _rotl(_acc4, 18);

      // merge round
      hash = _merge(hash, _acc1);
      hash = _merge(hash, _acc2);
      hash = _merge(hash, _acc3);
      hash = _merge(hash, _acc4);
    }

    hash += messageLength;

    // process the remaining data
    for (i = t = 0; t + 8 <= pos; ++i, t += 8) {
      hash ^= _accumulate(0, qbuffer[i]);
      hash = _rotl(hash, 27);
      hash *= prime64_1;
      hash += prime64_4;
    }
    for (i <<= 1; t + 4 <= pos; ++i, t += 4) {
      hash ^= sbuffer[i] * prime64_1;
      hash = _rotl(hash, 23);
      hash *= prime64_2;
      hash += prime64_3;
    }
    for (; t < pos; t++) {
      hash ^= buffer[t] * prime64_5;
      hash = _rotl(hash, 11);
      hash *= prime64_1;
    }

    // avalanche
    hash ^= hash >>> 33;
    hash *= prime64_2;
    hash ^= hash >>> 29;
    hash *= prime64_3;
    hash ^= hash >>> 32;

    return Uint8List.fromList([
      hash >>> 56,
      hash >>> 48,
      hash >>> 40,
      hash >>> 32,
      hash >>> 24,
      hash >>> 16,
      hash >>> 8,
      hash,
    ]);
  }
}

/// An instance of [XXHash64] with seed = 0
const XXHash64 xxh64 = XXHash64(0);

/// XXHash64 is a fast and efficient non-cryptographic hash function for
/// 64-bit platforms. It is designed for producing a quick and reliable hash
/// value for a given data, which can be used for many applications, such as
/// checksum, data validation, etc. In addition, it has a good distribution of
/// hash values, which helps to reduce [collisions][wiki].
///
/// This implementation was derived from https://github.com/Cyan4973/xxHash
///
/// [wiki]: https://github.com/Cyan4973/xxHash/wiki/Collision-ratio-comparison
///
/// **WARNING: It should not be used for cryptographic purposes.**
class XXHash64 extends BlockHashBase {
  final int seed;

  /// Creates a new instance of [XXHash64].
  ///
  /// Parameters:
  /// - [seed] is an optional 64-bit integer. Default: 0
  const XXHash64([this.seed = 0]);

  @override
  final String name = 'XXH64';

  @override
  XXHash64Sink createSink() => XXHash64Sink(seed);

  /// Get and instance of [XXHash64] with an specific seed
  XXHash64 withSeed(int seed) => XXHash64(seed);
}

/// Gets the 64-bit xxHash value of a String.
///
/// Parameters:
/// - [input] is the string to hash.
/// - The [encoding] is the encoding to use. Default is `input.codeUnits`.
int xxh64code(String input, [Encoding? encoding]) {
  return xxh64.string(input, encoding).number();
}

/// Gets the 64-bit xxHash hash of a String in hexadecimal.
///
/// Parameters:
/// - [input] is the string to hash.
/// - The [encoding] is the encoding to use. Default is `input.codeUnits`
String xxh64sum(String input, [Encoding? encoding]) {
  return xxh64.string(input, encoding).hex();
}

/// Extension to [String] to generate [xxh64] code.
extension XXHash64StringExtension on String {
  /// Gets the 64-bit xxHash value of a String.
  ///.
  /// Parameters:
  /// - If no [encoding] is defined, the `codeUnits` is used to get the bytes.
  int xxh64code([Encoding? encoding]) {
    return xxh64.string(this, encoding).number();
  }

  /// Gets the 64-bit xxHash hash of a String in hexadecimal.
  ///
  /// Parameters:
  /// - If no [encoding] is defined, the `codeUnits` is used to get the bytes.
  String xxh64sum([Encoding? encoding]) {
    return xxh64.string(this, encoding).hex();
  }
}