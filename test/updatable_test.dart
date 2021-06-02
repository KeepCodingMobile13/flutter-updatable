import 'package:updatable/src/keys.dart';
import 'package:test/test.dart';

void main() {
  group('Keys', () {
    late KeyMaker keys;

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
}
