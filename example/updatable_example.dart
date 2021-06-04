import 'package:updatable/updatable.dart';

void main() {
  final p = Person('Georgina'); // Model
  final logger = ChangeLogger().observee = p; // Observer

  p.name = 'Jerome'; // Loggers will log

  final me = SelfAbsorbedPerson('Elaine'); // Both
  me.name = 'Lisa';
}

/// A Model: domain class that include the Updatable mixin
class Person with Updatable {
  late String _name;
  String get name => _name;

  set name(String newValue) {
    changeState(() {
      _name = newValue;
    });
  }

  Person(this._name);

  @override
  String toString() {
    return '<$runtimeType: $_name>';
  }
}

/// A generic observer
class ChangeLogger<Model extends Updatable> {
  Model? _observee;
  Model? get observee => _observee;
  set observee(Model? other) {
    if (_observee != other) {
      _observee = other;
      _observee?.addObserver(nameWasChanged);
    }
  }

  int _changes = 0;
  int get changes => _changes;

  void nameWasChanged() {
    // ignore: avoid_print
    _changes += 1;
    // ignore: avoid_print
    print('$_observee has changed $_changes times!');
  }

  bool get isObserving => _observee != null;
}

/// Model and Observer at the same type
class SelfAbsorbedPerson extends Person {
  SelfAbsorbedPerson(String name) : super(name) {
    addObserver(navelStaring);
  }

  void navelStaring() {
    // ignore: avoid_print
    print('I just changed!');
  }
}
