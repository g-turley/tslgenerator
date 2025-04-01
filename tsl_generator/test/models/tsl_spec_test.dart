import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('TslSpecification', () {
    late File testFile;

    setUp(() {
      // Create a temporary test file
      testFile = File('test/temp_spec_test.tsl');
      testFile.writeAsStringSync('''
# Test Category
  Choice1:
    Option1.          [property Prop1]
    Option2.          [single]
    Option3.          [if Prop1]
''');
    });

    tearDown(() {
      // Clean up
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('can be created empty', () {
      final spec = TslSpecification();

      expect(spec.categories, isEmpty);
      expect(spec.properties, isEmpty);
      expect(spec.isEmpty, isTrue);
      expect(spec.isNotEmpty, isFalse);
    });

    test('can be created from categories', () {
      // Create a category and choice
      final category = Category('TestCategory');
      final choice = Choice('TestChoice.');

      // Add a property to the choice
      final property = Property('TestProp');
      choice.addProperty(property);

      // Add choice to category
      category.addChoice(choice);

      // Create specification from categories
      final spec = TslSpecification.fromCategories([category]);

      expect(spec.categories.length, equals(1));
      expect(spec.properties.length, equals(1));
      expect(spec.properties.containsKey('TestProp'), isTrue);
      expect(spec.isNotEmpty, isTrue);
    });

    test('can parse from file', () {
      final spec = TslSpecification.fromTslFile(testFile);

      expect(spec.categories.length, equals(1));
      expect(spec.categories[0].name, equals('Choice1'));
      expect(spec.categories[0].choices.length, equals(3));
      expect(spec.properties.length, equals(1));
      expect(spec.properties.containsKey('Prop1'), isTrue);
    });

    test('can parse from string', () {
      final tslContent = '''
# StringCategory
  Option1:
    Value1.          [property StringProp]
    Value2.          [if StringProp]
''';

      final spec = TslSpecification.fromString(tslContent);

      expect(spec.categories.length, equals(1));
      expect(spec.categories[0].name, equals('Option1'));
      expect(spec.categories[0].choices.length, equals(2));
      expect(spec.properties.length, equals(1));
      expect(spec.properties.containsKey('StringProp'), isTrue);
    });

    test('can programmatically build a specification', () {
      final spec = TslSpecification();

      // Create a category
      final category = Category('ProgrammaticCategory');

      // Create choices
      final choice1 = Choice('Choice1.');
      final choice2 = Choice('Choice2.');

      // Add choices to category
      category.addChoice(choice1);
      category.addChoice(choice2);

      // Add category to specification
      spec.addCategory(category);

      // Create and set properties
      final prop1 = spec.createProperty('Prop1', value: true);
      spec.setPropertyValue('Prop2', false);

      expect(spec.categories.length, equals(1));
      expect(spec.properties.length, equals(2));
      expect(prop1.value, isTrue);
      expect(spec.getProperty('Prop2')?.value, isFalse);
    });

    test('can reset all properties', () {
      final spec = TslSpecification();

      // Create properties with different values
      spec.createProperty('Prop1', value: true);
      spec.createProperty('Prop2', value: false);
      spec.createProperty('Prop3', value: true);

      // Reset all properties
      spec.resetAllProperties();

      // All properties should now be false
      for (final property in spec.properties.values) {
        expect(property.value, isFalse);
      }
    });

    test('can get property statistics', () {
      final spec = TslSpecification.fromTslFile(testFile);

      expect(spec.maxCategoryNameLength, equals('Choice1'.length));
      expect(spec.totalChoicesCount, equals(3));
    });

    test('handles getting nonexistent properties', () {
      final spec = TslSpecification();

      // Getting a nonexistent property should return null
      expect(spec.getProperty('NonexistentProp'), isNull);

      // Getting or creating a nonexistent property should create it
      final property = spec.getOrCreateProperty('NewProp');
      expect(property, isNotNull);
      expect(property.name, equals('NewProp'));
      expect(property.value, isFalse);

      // The property should now exist in the specification
      expect(spec.properties.containsKey('NewProp'), isTrue);
    });
  });
}
