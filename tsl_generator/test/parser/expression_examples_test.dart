// test/parser/expression_examples_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('TSL Expression Examples', () {
    late File testFile;

    setUp(() {
      // Create a temporary test file with properties
      testFile = File('test/expression_test.tsl');
      testFile.writeAsStringSync('''
# Setup Properties
  Test:
    PropA.          [property A]
    PropB.          [property B]
    PropC.          [property C]
    PropD.          [property D]
''');
    });

    tearDown(() {
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    /// Utility function to evaluate an expression with properties set according to the map
    bool evaluateExpression(
      String expression,
      Map<String, bool> propertyValues,
    ) {
      // Parse the existing file to create properties
      final parser = TslParser(testFile);
      final categories = parser.parse();

      // Set property values according to the provided map
      for (final entry in propertyValues.entries) {
        parser.getProperty(entry.key).value = entry.value;
      }

      // Create && evaluate the expression
      final expressionParser = ExpressionParser(parser);
      final expr = expressionParser.parse(expression);
      return expr.evaluate();
    }

    // Test cases from the documentation examples in paste.txt
    test('Example 1: [if A]', () {
      // Should evaluate to true only when A is true
      expect(evaluateExpression('A', {'A': true}), isTrue);
      expect(evaluateExpression('A', {'A': false}), isFalse);
    });

    test('Example 2: [if !B]', () {
      // Should evaluate to true only when B is false
      expect(evaluateExpression('!B', {'B': true}), isFalse);
      expect(evaluateExpression('!B', {'B': false}), isTrue);
    });

    test('Example 3: [if A || B]', () {
      // Should evaluate to true when either A || B is true
      expect(evaluateExpression('A || B', {'A': true, 'B': true}), isTrue);
      expect(evaluateExpression('A || B', {'A': true, 'B': false}), isTrue);
      expect(evaluateExpression('A || B', {'A': false, 'B': true}), isTrue);
      expect(evaluateExpression('A || B', {'A': false, 'B': false}), isFalse);
    });

    test('Example 4: [if A && B]', () {
      // Should evaluate to true only when both A && B are true
      expect(evaluateExpression('A && B', {'A': true, 'B': true}), isTrue);
      expect(evaluateExpression('A && B', {'A': true, 'B': false}), isFalse);
      expect(evaluateExpression('A && B', {'A': false, 'B': true}), isFalse);
      expect(evaluateExpression('A && B', {'A': false, 'B': false}), isFalse);
    });

    test('Example 5: [if !(A && B)]', () {
      // Should evaluate to true except when both A && B are true
      expect(evaluateExpression('!(A && B)', {'A': true, 'B': true}), isFalse);
      expect(evaluateExpression('!(A && B)', {'A': true, 'B': false}), isTrue);
      expect(evaluateExpression('!(A && B)', {'A': false, 'B': true}), isTrue);
      expect(
        evaluateExpression('!(A && B)', {'A': false, 'B': false}),
        isTrue,
      );
    });

    test('Example 6: [if A && B || C]', () {
      // Should evaluate with precedence: (A && B) || C
      expect(
        evaluateExpression('A && B || C', {'A': true, 'B': true, 'C': false}),
        isTrue,
      );
      expect(
        evaluateExpression('A && B || C', {'A': true, 'B': false, 'C': false}),
        isFalse,
      );
      expect(
        evaluateExpression('A && B || C', {'A': false, 'B': true, 'C': false}),
        isFalse,
      );
      expect(
        evaluateExpression('A && B || C', {'A': false, 'B': false, 'C': true}),
        isTrue,
      );
    });

    test('Example 7: [if A && (B || C) && D]', () {
      // Should evaluate with parentheses changing precedence
      // true only when A is true, either B || C is true, && D is true
      expect(
        evaluateExpression('A && (B || C) && D', {
          'A': true,
          'B': true,
          'C': false,
          'D': true,
        }),
        isTrue,
      );
      expect(
        evaluateExpression('A && (B || C) && D', {
          'A': true,
          'B': false,
          'C': true,
          'D': true,
        }),
        isTrue,
      );
      expect(
        evaluateExpression('A && (B || C) && D', {
          'A': true,
          'B': false,
          'C': false,
          'D': true,
        }),
        isFalse,
      );
      expect(
        evaluateExpression('A && (B || C) && D', {
          'A': true,
          'B': true,
          'C': true,
          'D': false,
        }),
        isFalse,
      );
      expect(
        evaluateExpression('A && (B || C) && D', {
          'A': false,
          'B': true,
          'C': true,
          'D': true,
        }),
        isFalse,
      );
    });

    test('Example 8: [if A || !B && !C]', () {
      // Should evaluate with precedence: A || (!B && !C)
      expect(
        evaluateExpression('A || !B && !C', {'A': true, 'B': true, 'C': true}),
        isTrue,
      );
      expect(
        evaluateExpression('A || !B && !C', {
          'A': false,
          'B': false,
          'C': false,
        }),
        isTrue,
      );
      expect(
        evaluateExpression('A || !B && !C', {
          'A': false,
          'B': true,
          'C': false,
        }),
        isFalse,
      );
      expect(
        evaluateExpression('A || !B && !C', {
          'A': false,
          'B': false,
          'C': true,
        }),
        isFalse,
      );
    });

    test('Example 9: [if !(!A || B) && C || D]', () {
      // Complex expression from documentation
      // !(!A || B) is equivalent to (A && !B)
      // So this is (A && !B) && C || D
      // Which is ((A && !B) && C) || D with operator precedence
      expect(
        evaluateExpression('!(!A || B) && C || D', {
          'A': true,
          'B': false,
          'C': true,
          'D': false,
        }),
        isTrue,
      );
      expect(
        evaluateExpression('!(!A || B) && C || D', {
          'A': false,
          'B': false,
          'C': true,
          'D': false,
        }),
        isFalse,
      );
      expect(
        evaluateExpression('!(!A || B) && C || D', {
          'A': true,
          'B': true,
          'C': true,
          'D': false,
        }),
        isFalse,
      );
      expect(
        evaluateExpression('!(!A || B) && C || D', {
          'A': false,
          'B': false,
          'C': false,
          'D': true,
        }),
        isTrue,
      );
    });

    test('Test Case with If Else Pattern from Example', () {
      // Test a realistic case like from the bug report
      testFile = File('test/if_else_error_test.tsl');
      testFile.writeAsStringSync('''
# Options
First Category:
  First Option. [property excludeLinesOption]
  Second Option. [property keepLinesOption]
  
Second Category:
  Case Sensitive. [property noCaseInsensitiveOption]
  Case Insensitive. [if !(excludeLinesOption || keepLinesOption)][error][else]
''');

      // Parse the file && generate frames
      final parser = TslParser(testFile);
      final categories = parser.parse();
      final generator = FrameGenerator(categories);
      final result = generator.generate();

      // Verify that we have the expected error frame with the "if" branch
      // since the condition would be true when both options are false
      final errorFrames = result.errorFramesList;

      // Should generate an error frame for the Case Insensitive choice
      expect(errorFrames.length, greaterThan(0));

      // Find the frame for Case Insensitive
      final caseInsensitiveFrame = errorFrames.firstWhere(
        (frame) => frame.categoriesAndChoices.values.any(
          (choice) => choice?.name == 'Case Insensitive',
        ),
        orElse: () => TestFrame(0), // Dummy frame that will fail the test
      );

      // Verify it's really an error frame
      expect(caseInsensitiveFrame.frameType, equals(FrameType.error));

      // Verify it follows the "if" branch
      expect(caseInsensitiveFrame.fromIfElse, isTrue);
      expect(caseInsensitiveFrame.ifElseBranch, equals('if'));
    });
  });
}
