import 'package:updatable/src/keys.dart';
import 'package:updatable/src/updatable_mixin.dart';

import 'package:test/test.dart';

void main() {
  late ChangesCounter counter;
  late Person paco;
  late List<ChangesCounter> counters;
  const int size = 5;

  Future<void> changePerson(Person person, String newName) async {
    person.name = newName;
  }

  Future<void> reentrantUpdate(Person person, String name) async {
    person.reentrantName(name);
  }

  group('Updatable', () {
    setUp(() {
      counter = ChangesCounter();
      paco = Person('Paco');
      counters = [for (int i = 0; i < size; i++) ChangesCounter()];
    });

    test('creation', () {
      expect(() => Person('Luke'), returnsNormally);
      expect(Person('Chewie'), isNotNull);
    });

    test('Add subscriber', () {
      expect(paco.isBeingObserved(counter.inc), isFalse);
      expect(() => paco.addObserver(counter.inc), returnsNormally);
      expect(paco.isBeingObserved(counter.inc), isTrue);
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

    test('observers are notified', () async {
      paco.addObserver(counter.inc);
      await changePerson(paco, 'Dart Vader'); // should trigger notification
      expect(counter.totalCalls, 1);
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
    }, skip: true);

    test('Recurrent changes send only one notification', () async {
      paco.addObserver(counter.inc);
      expect(counter.totalCalls, 0);

      await reentrantUpdate(paco, 'Yoda');

      expect(counter.totalCalls, 1);
    }, skip: true);

    // test('Add same susbcriber n times adds only 1', () {
    //   const int size = 100;

    //   // Add junk before adding the same one
    //   for (int i = 0; i < size; i++) {
    //     paco.addObserver(() {});
    //   }
    //   // Add the same one, size times
    //   expect(paco.observerCount, size);
    //   for (int i = 0; i < size; i++) {
    //     paco.addObserver(counter.notifyMe);
    //   }
    //   expect(paco.observerCount, size + 1);
    // }, skip: true);

    test('Is observing', () {
      const int size = 10;
      final obs = [for (int i = 0; i < size; i++) ChangesCounter()];
      for (final ChangesCounter each in obs) {
        paco.addObserver(each.inc);
        expect(paco.isBeingObserved(each.inc), isTrue);
      }
    }, skip: true);

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
    }, skip: true);

    test('Add n observers and have n observers', () {
      // Add
      const int size = 621;
      final List<ChangesCounter> observers = [
        for (int i = 0; i < size; i++) ChangesCounter()
      ];
      for (final ChangesCounter each in observers) {
        paco.addObserver(each.inc);
      }
      //expect(paco.observerCount, size);
      for (final ChangesCounter each in observers) {
        paco.isBeingObserved(each.inc);
      }
    }, skip: true);

    //   test('add and then remove non-identical does nothing', () {
    //     // Add
    //     const int size = 621;
    //     final List<ChangesCounter> observers = [
    //       for (int i = 0; i < size; i++) ChangesCounter()
    //     ];
    //     for (int i = 0; i < size; i++) {
    //       paco.addObserver(observers[i].notifyMe);
    //     }
    //     expect(paco.observerCount, size);

    //     // remove non-identicals
    //     for (int i = 0; i < size; i++) {
    //       paco.removeObserver(() {});
    //     }
    //     expect(paco.observerCount, size);
    //   }, skip: true);
  });
}

class Person with Updatable {
  late String _name;
  String get name => _name;
  set name(String newOne) {
    changeState(() {
      _name = name;
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
    print('Received notification: $_totalCalls');
  }
}
