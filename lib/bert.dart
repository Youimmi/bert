library bert;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Decode data serialized with :erlang.term_to_binary/1
List<dynamic> decode(Uint8List buffer) {
  ByteData data = ByteData.sublistView(buffer);
  int index = 0;

  if (data.getUint8(index) != 131) {
    throw ("BERT?");
  }

  index += 1;

  return _decodeType(data, () => index, (int increment) => index += increment);
}

int _decodeBigBignum(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int skip = data.getInt32(_getIndex());
  _incrementIndex(4);
  return _decodeBignum(data, _getIndex, _incrementIndex, skip);
}

int _decodeBignum(
    ByteData data, Function _getIndex, Function _incrementIndex, int skip) {
  int result = 0;
  int sig = data.getUint8(_getIndex());
  _incrementIndex(1);
  int count = skip;
  while (count-- > 0) {
    result = 256 * result + data.getUint8(_getIndex() + count);
  }
  _incrementIndex(skip);
  return result * (sig == 0 ? 1 : -1);
}

Uint8List _decodeCharlist(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint16(_getIndex());
  _incrementIndex(2);
  Uint8List result = Uint8List.view(data.buffer, _getIndex(), size);
  _incrementIndex(size);
  return result;
}

double _decodeFlo(ByteData data, Function _getIndex, Function _incrementIndex) {
  double result =
      double.parse(utf8.decode(data.buffer.asUint8List(_getIndex(), 31)));
  _incrementIndex(31);
  return result;
}

double _decodeIee(ByteData data, Function _getIndex, Function _incrementIndex) {
  double result =
      _readFloat(Uint8List.view(data.buffer, _getIndex(), 8), 0, false, 52, 8);
  _incrementIndex(8);
  return result;
}

int _decodeInt(ByteData data, Function _getIndex, Function _incrementIndex) {
  int result = data.getInt32(_getIndex());
  _incrementIndex(4);
  return result;
}

List<dynamic> _decodeList32(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint32(_getIndex());
  List<dynamic> result = [];
  _incrementIndex(4);
  for (int i = 0; i < size; i++) {
    result.add(_decodeType(data, _getIndex, _incrementIndex));
  }
  _decodeType(data, _getIndex, _incrementIndex);
  return result;
}

Map<String, dynamic> _decodeMap(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint32(_getIndex());
  Map<String, dynamic> result = {};
  _incrementIndex(4);
  for (int i = 0; i < size; i++) {
    String key = _decodeType(data, _getIndex, _incrementIndex);
    result[key] = _decodeType(data, _getIndex, _incrementIndex);
  }
  return result;
}

int _decodeSmallBignum(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int skip = data.getUint8(_getIndex());
  _incrementIndex(1);
  return _decodeBignum(data, _getIndex, _incrementIndex, skip);
}

String _decodeString16(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint16(_getIndex());
  _incrementIndex(2);
  Uint8List result = data.buffer.asUint8List(_getIndex(), size);
  _incrementIndex(size);
  return _utf8Arr(result);
}

String _decodeString32(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint32(_getIndex());
  _incrementIndex(4);
  Uint8List result = data.buffer.asUint8List(_getIndex(), size);
  _incrementIndex(size);
  return _utf8Arr(result);
}

String _decodeString8(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint8(_getIndex());
  _incrementIndex(1);
  Uint8List result = data.buffer.asUint8List(_getIndex(), size);
  _incrementIndex(size);
  return _utf8Arr(result);
}

int _decodeTinyInt(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int result = data.getUint8(_getIndex());
  _incrementIndex(1);
  return result;
}

List<dynamic> _decodeTuple(
    ByteData data, Function _getIndex, Function _incrementIndex, int size) {
  List<dynamic> result = [];
  for (int i = 0; i < size; i++) {
    result.add(_decodeType(data, _getIndex, _incrementIndex));
  }
  return result;
}

List<dynamic> _decodeTuple32(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint32(_getIndex());
  _incrementIndex(4);
  return _decodeTuple(data, _getIndex, _incrementIndex, size);
}

List<dynamic> _decodeTuple8(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int size = data.getUint8(_getIndex());
  _incrementIndex(1);
  return _decodeTuple(data, _getIndex, _incrementIndex, size);
}

dynamic _decodeType(
    ByteData data, Function _getIndex, Function _incrementIndex) {
  int type = data.getUint8(_getIndex());
  _incrementIndex(1);
  switch (type) {
    case 97:
      return _decodeTinyInt(data, _getIndex, _incrementIndex);
    case 98:
      return _decodeInt(data, _getIndex, _incrementIndex);
    case 99:
      return _decodeFlo(data, _getIndex, _incrementIndex);
    case 70:
      return _decodeIee(data, _getIndex, _incrementIndex);
    case 100:
      return _decodeString16(data, _getIndex, _incrementIndex);
    case 104:
      return _decodeTuple8(data, _getIndex, _incrementIndex);
    case 107:
      return _decodeCharlist(data, _getIndex, _incrementIndex);
    case 108:
      return _decodeList32(data, _getIndex, _incrementIndex);
    case 109:
      return _decodeString32(data, _getIndex, _incrementIndex);
    case 110:
      return _decodeSmallBignum(data, _getIndex, _incrementIndex);
    case 111:
      return _decodeBigBignum(data, _getIndex, _incrementIndex);
    case 115:
      return _decodeString8(data, _getIndex, _incrementIndex);
    case 118:
      return _decodeString16(data, _getIndex, _incrementIndex);
    case 119:
      return _decodeString8(data, _getIndex, _incrementIndex);
    case 105:
      return _decodeTuple32(data, _getIndex, _incrementIndex);
    case 116:
      return _decodeMap(data, _getIndex, _incrementIndex);
    default:
      return [];
  }
}

double _readFloat(
    Uint8List buffer, int offset, bool isLE, int mLen, int nBytes) {
  int e, m;
  var eLen = (nBytes * 8) - mLen - 1;
  var eMax = (1 << eLen) - 1;
  var eBias = eMax >> 1;
  var nBits = -7;
  var i = isLE ? (nBytes - 1) : 0;
  var d = isLE ? -1 : 1;
  var s = buffer[offset + i];
  i += d;
  e = s & ((1 << (-nBits)) - 1);
  s >>= (-nBits);
  nBits += eLen;
  for (; nBits > 0; e = (e * 256) + buffer[offset + i], i += d, nBits -= 8) {}
  m = e & ((1 << (-nBits)) - 1);
  e >>= (-nBits);
  nBits += mLen;
  for (; nBits > 0; m = (m * 256) + buffer[offset + i], i += d, nBits -= 8) {}
  if (e == 0) {
    e = 1 - eBias;
  } else if (e == eMax) {
    return m != 0 ? double.nan : ((s != 0 ? -1 : 1) * double.infinity);
  } else {
    m = m + pow(2, mLen).toInt();
    e = e - eBias;
  }
  return ((s != 0 ? -1 : 1) * m * pow(2, e - mLen)).toDouble();
}

String _utf8Arr(dynamic ab) {
  if (ab is! Uint8List) {
    ab = Uint8List.fromList(_utf8Enc(ab)).buffer;
  }
  return _utf8Dec(ab);
}

String _utf8Dec(Uint8List ab) => utf8.decode(ab);

List<int> _utf8Enc(String ab) => utf8.encode(ab);
