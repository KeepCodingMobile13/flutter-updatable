import 'package:updatable/src/updatable_mixin.dart';

import 'package:test/test.dart';

class Person with Updatable {
  late String _name;

  String get name => _name;
  set name(String newOne) {
    changeState(() {
      _name = name;
    });
  }

  late int _age;
  int get age => _age;
  void changeAge(int newAge, [int times = 42]) {
    batchChangeState(() {
      for (int i = 0; i < times; i++) {
        _age = newAge;
      }
    });
  }

  void reentrantName(String newOne) {
    changeState(() {
      name = newOne;
      name = newOne;
    });
  }

  Person(this._name);
}

class ChangesCounter {
  int _totalCalls = 0;
  int get totalCalls => _totalCalls;

  void inc() {
    _totalCalls++;
  }
}

void main() {
  late ChangesCounter counter;
  late Person paco;
  late List<ChangesCounter> counters;
  const int size = 101;

  Future<void> changePerson(Person person, String newName) async {
    person.name = newName;
  }

  Future<void> reentrantUpdate(Person person, String name) async {
    person.reentrantName(name);
  }

  setUp(() {
    counter = ChangesCounter();
    paco = Person('Paco');
    counters = [for (int i = 0; i < size; i++) ChangesCounter()];
  });

  group('Single Changes', () {
    test('creation', () {
      expect(() => Person('Luke'), returnsNormally);
      expect(Person('Chewie'), isNotNull);
    });

    test('Add 1 subscriber', () {
      expect(paco.isBeingObserved(counter.inc), isFalse);
      expect(() => paco.addObserver(counter.inc), returnsNormally);
      expect(paco.isBeingObserved(counter.inc), isTrue);
    });

    test('Add n subscribers', () {
      // add the observers
      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }

      // check that they are there
      for (final ChangesCounter each in counters) {
        expect(paco.isBeingObserved(each.inc), isTrue);
      }
    });

    test('Add n non-identical susbcribers and they will be found', () {
      // nobody yet
      for (final ChangesCounter each in counters) {
        expect(paco.isBeingObserved(each.inc), isFalse);
      }

      // Add them
      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }

      // Better be there
      for (final ChangesCounter each in counters) {
        paco.isBeingObserved(each.inc);
      }
    });

    test('Non identical will not be found', () {
      paco.addObserver(counter.inc);
      expect(paco.isBeingObserved(counter.inc), isTrue);

      // A equal but non identicall will no tbe found
      final ChangesCounter other = ChangesCounter();
      expect(paco.isBeingObserved(other.inc), isFalse);

      paco.addObserver(() {});
      expect(paco.isBeingObserved(() {}), isFalse);
    });

    test('1 observer 1 change, 1 notificaton', () async {
      paco.addObserver(counter.inc);
      await changePerson(paco, 'Dart Vader'); // should trigger notification
      expect(counter.totalCalls, 1);
    });

    test('1 observer, 1 Recurrent change send 1 notification', () async {
      paco.addObserver(counter.inc);
      expect(counter.totalCalls, 0);

      await reentrantUpdate(paco, 'Yoda');

      expect(counter.totalCalls, 1);
    }, skip: false);

    test('1 observer, n changes, n notifications', () async {
      paco.addObserver(counter.inc);

      for (int i = 0; i < size; i++) {
        await changePerson(paco, 'Jaarl');
      }

      expect(counter.totalCalls, size);
    });

    test('1 observer, n recurrent changes, n notifications', () async {
      paco.addObserver(counter.inc);

      for (int i = 0; i < size; i++) {
        await reentrantUpdate(paco, 'Manolo Escobar');
      }

      expect(counter.totalCalls, size);
    });

    test('n observers, 1 change, each gets 1 notification', () async {
      // add n observers
      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }
      // cause 1 update
      await changePerson(paco, 'Ted');

      // all observers get it
      for (final ChangesCounter each in counters) {
        expect(each.totalCalls, 1);
      }
    });

    test('n observers, 1 recursive change, each gets 1 notification', () async {
      // add n observers
      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }
      // cause 1 update
      await reentrantUpdate(paco, "neo");

      // all observers get it
      for (final ChangesCounter each in counters) {
        expect(each.totalCalls, 1);
      }
    });

    test('n observers, n recursive change, each gets n notifications',
        () async {
      // add n observers
      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }
      for (int i = 0; i < size; i++) {
        await reentrantUpdate(paco, "neo");
      }

      // all observers get it
      for (final ChangesCounter each in counters) {
        expect(each.totalCalls, size);
      }
    });

    test(
        'Add n different observers, and n different notifications will be sent',
        () async {
      const int size = 2;

      final List<ChangesCounter> counters = [
        for (int i = 0; i < size; i++) ChangesCounter()
      ];

      for (final ChangesCounter each in counters) {
        paco.addObserver(each.inc);
      }

      await changePerson(paco, 'Darth Maul');

      // comprobar que cada uno de los canges ha recibido el suyo
      for (final ChangesCounter each in counters) {
        expect(each.totalCalls, 1);
      }
    });

    test('Add n observers, make 1 change, get n notifications', () async {
      const int size = 845;
      final obs = [for (int i = 0; i < size; i++) ChangesCounter()];

      for (final ChangesCounter each in obs) {
        paco.addObserver(each.inc);
      }

      await changePerson(paco, 'Minch Yoda');

      for (final ChangesCounter each in obs) {
        expect(each.totalCalls, 1);
      }
    }, skip: false);

    group("batch Changes", () {
      test(
          'One batch change with a single notification, causes one  notification',
          () {
        paco.addObserver(counter.inc);
        paco.changeAge(
            51, 100); // will set the age 100 times, should cause 1 notification
        expect(counter.totalCalls, 1);
      });

      test('1 batch change with n observers causes 1 notification per observer',
          () {
        for (final ChangesCounter each in counters) {
          paco.addObserver(each.inc);
        }

        paco.changeAge(41, 120);

        for (final ChangesCounter each in counters) {
          expect(each.totalCalls, 1);
        }
      }, skip: false);

      test('n batch changes with n observers, causes n notifications', () {
        const int times = 23;

        for (final ChangesCounter each in counters) {
          paco.addObserver(each.inc);
        }

        for (int i = 0; i < times; i++) {
          paco.changeAge(41, 120);
        }

        for (final ChangesCounter each in counters) {
          expect(each.totalCalls, times);
        }
      });
    });
  });
}
