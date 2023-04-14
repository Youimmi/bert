# bert

ETF (External Term Format) and BERT (Binary ERlang Term) decoder

## Description

This decoder allows you to deserialize data, for example from a socket, which is serialized with [:erlang.term_to_binary/1](https://www.erlang.org/doc/man/erlang.html#term_to_binary-1)

## Usage

```dart
import 'package:bert/bert.dart' as bert;

// List<dynamic> decode(Uint8List buffer)
bert.decode(buffer)
```