A library for Dart developers.

## Usage

A simple usage example:

```dart
import 'package:updatable/updatable.dart';

void main() {
  final joe = SelfAbsorbedPerson('Joe');
  joe.name = '';
}

/// Class that observes its own changes
class SelfAbsorbedPerson with Updatable {
  String _name = 'Bob';
  String get name => _name;

  set name(String newValue) {
    changeState(() {
      _name = newValue;
    });
  }

  void nameChanged() {
    // ignore: avoid_print
    print('My name is now: $name');
  }

  SelfAbsorbedPerson() {
    addObserver(nameChanged);
  }
}


```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
