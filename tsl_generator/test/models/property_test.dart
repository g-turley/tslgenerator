import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('Property', () {
    test('can be created with default values', () {
      final property = Property('test');
      expect(property.name, equals('test'));
      expect(property.value, equals(false));
    });

    test('can be created with a specified value', () {
      final property = Property('test', value: true);
      expect(property.name, equals('test'));
      expect(property.value, equals(true));
    });

    test('has correct equality', () {
      final property1 = Property('test');
      final property2 = Property('test');
      final property3 = Property('other');

      expect(property1, equals(property2));
      expect(property1, isNot(equals(property3)));
    });

    test('has correct hashcode', () {
      final property1 = Property('test');
      final property2 = Property('test');

      expect(property1.hashCode, equals(property2.hashCode));
    });

    test('can change value', () {
      final property = Property('test');
      expect(property.value, equals(false));

      property.value = true;
      expect(property.value, equals(true));
    });

    test('has correct string representation', () {
      final property = Property('test');
      expect(property.toString(), equals('Property(test: false)'));
    });
  });
}
