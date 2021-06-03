import 'package:updatable/updatable.dart';

void main() {
  final p = SelfAbsorbedPerson();
  p.name = 'Jerome';
}

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
