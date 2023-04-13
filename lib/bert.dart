library bert;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

List<dynamic> decode(Uint8List buffer) {
  ByteData data = ByteData.sublistView(buffer);
  int index = 0;

  if (data.getUint8(index) != 131) {
    throw ("BERT?");
  }

  index += 1;

  return decodeType(data, () => index, (int increment) => index += increment);
}

int decodeBigBignum(ByteData data, Function getIndex, Function incrementIndex) {
  int skip = data.getInt32(getIndex());
  incrementIndex(4);
  return decodeBignum(data, getIndex, incrementIndex, skip);
}

int decodeBignum(
    ByteData data, Function getIndex, Function incrementIndex, int skip) {
  int result = 0;
  int sig = data.getUint8(getIndex());
  incrementIndex(1);
  int count = skip;
  while (count-- > 0) {
    result = 256 * result + data.getUint8(getIndex() + count);
  }
  incrementIndex(skip);
  return result * (sig == 0 ? 1 : -1);
}

Uint8List decodeCharlist(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint16(getIndex());
  incrementIndex(2);
  Uint8List result = Uint8List.view(data.buffer, getIndex(), size);
  incrementIndex(size);
  return result;
}

double decodeFlo(ByteData data, Function getIndex, Function incrementIndex) {
  double result =
      double.parse(utf8.decode(data.buffer.asUint8List(getIndex(), 31)));
  incrementIndex(31);
  return result;
}

double decodeIee(ByteData data, Function getIndex, Function incrementIndex) {
  double result =
      readFloat(Uint8List.view(data.buffer, getIndex(), 8), 0, false, 52, 8);
  incrementIndex(8);
  return result;
}

int decodeInt(ByteData data, Function getIndex, Function incrementIndex) {
  int result = data.getInt32(getIndex());
  incrementIndex(4);
  return result;
}

List<dynamic> decodeList32(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint32(getIndex());
  List<dynamic> result = [];
  incrementIndex(4);
  for (int i = 0; i < size; i++) {
    result.add(decodeType(data, getIndex, incrementIndex));
  }
  decodeType(data, getIndex, incrementIndex);
  return result;
}

Map<String, dynamic> decodeMap(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint32(getIndex());
  Map<String, dynamic> result = {};
  incrementIndex(4);
  for (int i = 0; i < size; i++) {
    String key = decodeType(data, getIndex, incrementIndex);
    result[key] = decodeType(data, getIndex, incrementIndex);
  }
  return result;
}

int decodeSmallBignum(
    ByteData data, Function getIndex, Function incrementIndex) {
  int skip = data.getUint8(getIndex());
  incrementIndex(1);
  return decodeBignum(data, getIndex, incrementIndex, skip);
}

String decodeString16(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint16(getIndex());
  incrementIndex(2);
  Uint8List result = data.buffer.asUint8List(getIndex(), size);
  incrementIndex(size);
  return utf8Arr(result);
}

String decodeString32(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint32(getIndex());
  incrementIndex(4);
  Uint8List result = data.buffer.asUint8List(getIndex(), size);
  incrementIndex(size);
  return utf8Arr(result);
}

String decodeString8(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint8(getIndex());
  incrementIndex(1);
  Uint8List result = data.buffer.asUint8List(getIndex(), size);
  incrementIndex(size);
  return utf8Arr(result);
}

int decodeTinyInt(ByteData data, Function getIndex, Function incrementIndex) {
  int result = data.getUint8(getIndex());
  incrementIndex(1);
  return result;
}

List<dynamic> decodeTuple(
    ByteData data, Function getIndex, Function incrementIndex, int size) {
  List<dynamic> result = [];
  for (int i = 0; i < size; i++) {
    result.add(decodeType(data, getIndex, incrementIndex));
  }
  return result;
}

List<dynamic> decodeTuple32(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint32(getIndex());
  incrementIndex(4);
  return decodeTuple(data, getIndex, incrementIndex, size);
}

List<dynamic> decodeTuple8(
    ByteData data, Function getIndex, Function incrementIndex) {
  int size = data.getUint8(getIndex());
  incrementIndex(1);
  return decodeTuple(data, getIndex, incrementIndex, size);
}

dynamic decodeType(ByteData data, Function getIndex, Function incrementIndex) {
  int type = data.getUint8(getIndex());
  incrementIndex(1);
  switch (type) {
    case 97:
      return decodeTinyInt(data, getIndex, incrementIndex);
    case 98:
      return decodeInt(data, getIndex, incrementIndex);
    case 99:
      return decodeFlo(data, getIndex, incrementIndex);
    case 70:
      return decodeIee(data, getIndex, incrementIndex);
    case 100:
      return decodeString16(data, getIndex, incrementIndex);
    case 104:
      return decodeTuple8(data, getIndex, incrementIndex);
    case 107:
      return decodeCharlist(data, getIndex, incrementIndex);
    case 108:
      return decodeList32(data, getIndex, incrementIndex);
    case 109:
      return decodeString32(data, getIndex, incrementIndex);
    case 110:
      return decodeSmallBignum(data, getIndex, incrementIndex);
    case 111:
      return decodeBigBignum(data, getIndex, incrementIndex);
    case 115:
      return decodeString8(data, getIndex, incrementIndex);
    case 118:
      return decodeString16(data, getIndex, incrementIndex);
    case 119:
      return decodeString8(data, getIndex, incrementIndex);
    case 105:
      return decodeTuple32(data, getIndex, incrementIndex);
    case 116:
      return decodeMap(data, getIndex, incrementIndex);
    default:
      return [];
  }
}

double readFloat(
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

String utf8Arr(dynamic ab) {
  if (ab is! Uint8List) {
    ab = Uint8List.fromList(utf8Enc(ab)).buffer;
  }
  return utf8Dec(ab);
}

String utf8Dec(Uint8List ab) {
  return utf8.decode(ab);
}

List<int> utf8Enc(String ab) {
  return utf8.encode(ab);
}
