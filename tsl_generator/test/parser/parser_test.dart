import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('TslParser', () {
    late File testFile;

    setUp(() {
      // Create a temporary test file
      testFile = File('test/temp_test.tsl');
      testFile.writeAsStringSync('''
# Test Category

  Category1:
    Choice1.          [property Prop1]
    Choice2.          [single]
    Choice3.          [error]
    Choice4.          [if Prop1]

  Category2:
    ChoiceA.
    ChoiceB.          [if !Prop1] [property Prop2]
    ChoiceC.          [if Prop1 && Prop2]
''');
    });

    tearDown(() {
      // Delete the temporary file
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('can parse a TSL file', () {
      final parser = TslParser(testFile);
      final categories = parser.parse();

      expect(categories.length, equals(2));

      // Check first category
      final category1 = categories[0];
      expect(category1.name, equals('Category1'));
      expect(category1.choices.length, equals(4));

      // Check choices in first category
      expect(category1.choices[0].name, equals('Choice1.'));
      expect(category1.choices[0].properties.length, equals(1));
      expect(category1.choices[0].properties[0].name, equals('Prop1'));

      expect(category1.choices[1].name, equals('Choice2.'));
      expect(category1.choices[1].frameType, equals(FrameType.single));

      expect(category1.choices[2].name, equals('Choice3.'));
      expect(category1.choices[2].frameType, equals(FrameType.error));

      expect(category1.choices[3].name, equals('Choice4.'));
      expect(category1.choices[3].hasIfExpression, isTrue);

      // Check second category
      final category2 = categories[1];
      expect(category2.name, equals('Category2'));
      expect(category2.choices.length, equals(3));

      // Check choices in second category
      expect(category2.choices[0].name, equals('ChoiceA.'));

      expect(category2.choices[1].name, equals('ChoiceB.'));
      expect(category2.choices[1].hasIfExpression, isTrue);
      expect(category2.choices[1].ifProperties.length, equals(1));
      expect(category2.choices[1].ifProperties[0].name, equals('Prop2'));

      expect(category2.choices[2].name, equals('ChoiceC.'));
      expect(category2.choices[2].hasIfExpression, isTrue);
    });

    test('throws exception for invalid files', () {
      final nonExistentFile = File('non_existent.tsl');

      expect(
        () => TslParser(nonExistentFile).parse(),
        throwsA(isA<TslParserException>()),
      );
    });
  });
}
