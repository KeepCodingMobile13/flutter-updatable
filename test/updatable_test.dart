import 'package:updatable/src/keys.dart';
import 'package:updatable/src/updatable_mixin.dart';

import 'package:test/test.dart';

void main() {
  late KeyMaker keys;
  late ChangesCounter counter;
  late Person paco;
  group('Keys', () {
    setUp(() {
      keys = KeyMaker();
    });

    test('Create', () {
      expect(() => Key(42), returnsNormally);
      expect(Key(1202), isNotNull);

      expect(() => KeyMaker(), returnsNormally);
      expect(KeyMaker(), isNotNull);
    });

    test('Ordered next keys', () {
      for (int i = 0; i < 100; i++) {
        expect(keys.next.value, i);
      }
    });
  });

  group('Updatable', () {
    setUp(() {
      keys = KeyMaker();
      counter = ChangesCounter();
      paco = Person('Paco');
    });

    test('creation', () {
      expect(() => Person('Luke'), returnsNormally);
      expect(Person('Chewie'), isNotNull);
    });

    test('Add subscriber', () {
      expect(paco.observerCount, 0);
      expect(() => paco.addObserver(counter.notifyMe), returnsNormally);
      expect(paco.observerCount, 1);
    });

    test('Add and thou shall find', () {
      paco.addObserver(counter.notifyMe);
      expect(paco.isObserving(counter.notifyMe), isTrue);

      // A non identicall will no tbe found
      final ChangesCounter other = ChangesCounter();
      expect(paco.isObserving(other.notifyMe), isFalse);

      paco.addObserver(() {});
      expect(paco.isObserving(() {}), isFalse);
    });

    test('observers are notified', () async {
      Future<void> changeName(String newName) async {
        paco.name = newName;
      }

      paco.addObserver(counter.notifyMe);
      await changeName('Dart Vader'); // should trigger notification
      expect(counter.totalCalls, 1);
    });

    test(
        'Add n different observers, and n different notifications will be sent',
        () async {
      const int size = 50;

      final List<ChangesCounter> counters = [
        for (int i = 0; i < size; i++) ChangesCounter()
      ];

      for (final ChangesCounter each in counters) {
        paco.addObserver(each.notifyMe);
      }

      Future<void> update() async {
        paco.name = "Paco Escobar";
      }

      await update();

      // comprobar que cada uno de los canges ha recibido el suyo
      for (final ChangesCounter each in counters) {
        expect(each.totalCalls, 1);
      }
    });

    test('Recurrent changes send only one notification', () async {
      paco.addObserver(counter.notifyMe);
      expect(counter.totalCalls, 0);

      Future<void> reentrantUpdate() async {
        paco.reentrantName('pedorro');
      }

      await reentrantUpdate();

      expect(counter.totalCalls, 1);
    });

    test('Add same susbcriber n times adds only 1', () {
      const int size = 100;

      // Add junk before adding the same one
      for (int i = 0; i < size; i++) {
        paco.addObserver(() {});
      }
      // Add the same one, size times
      expect(paco.observerCount, size);
      for (int i = 0; i < size; i++) {
        paco.addObserver(counter.notifyMe);
      }
      expect(paco.observerCount, size + 1);
    });

    test('add and then remove non-identical does nothing', () {
      // Add
      const int size = 621;
      for (int i = 0; i < size; i++) {
        paco.addObserver(() {});
      }
      expect(paco.observerCount, size);

      // remove non-identicals
      for (int i = 0; i < size; i++) {
        paco.removeObserver(() {});
      }
      expect(paco.observerCount, size);
    });
  });

  // test('Un referenced observers are forgotten', () async {
  //   () {
  //     final ChangesCounter goner = ChangesCounter();
  //     paco.addObserver(goner.notifyMe);
  //   }();

  //   Future<void> update() async {
  //     paco.name = 'Moncho';
  //   }

  //   await update();
  //   paco.removeObserver(() {});
  //   expect(paco.observerCount, 0);
  // });
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

  void notifyMe() => _totalCalls++;
}
