import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/src/errors/tsl_errors.dart';
import 'package:tsl_generator/src/parser/tsl_parser.dart';

void main() {
  group('Improved TslParser Error Handling', () {
    late File testFile;

    setUp(() {
      // We'll create the test file in each test to have different content
    });

    tearDown(() {
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('throws TslError for non-existent file', () {
      testFile = File('non_existent_file.tsl');
      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.fileSystem &&
                e.message.contains('does not exist'),
          ),
        ),
      );
    });

    test('throws TslError for empty file', () {
      testFile = File('test/empty_file.tsl');
      testFile.writeAsStringSync('');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains('No valid categories found'),
          ),
        ),
      );
    });

    test('throws TslError for missing category before choice', () {
      testFile = File('test/no_category.tsl');
      testFile.writeAsStringSync('''
Choice1.          [property Prop1]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains('Choice must be preceded by a category') &&
                e.lineNumber == 1,
          ),
        ),
      );
    });

    test('throws TslError for invalid constraint', () {
      testFile = File('test/invalid_constraint.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [unknown_constraint]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.constraint &&
                e.message.contains('Unknown constraint') &&
                e.lineNumber == 2 &&
                e.suggestion != null,
          ),
        ),
      );
    });

test('throws TslError for undefined property in expression', () {
      testFile = File('test/undefined_property.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [property PropA]
  Choice2.        [if PropB]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.property &&
                e.message.contains('PropB') &&
                e.message.contains('not defined') &&
                e.lineNumber == 3 &&
                e.suggestion != null,
          ),
        ),
      );
    });
    test('throws TslError for unmatched parenthesis', () {
      testFile = File('test/unmatched_paren.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [property PropA]
  Choice2.        [property PropB]
  Choice3.        [if PropA && (PropB]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.expression &&
                e.message.contains('Unmatched opening parenthesis') &&
                e.suggestion != null,
          ),
        ),
      );
    });

    test('throws TslError with suggestion for property name', () {
      testFile = File('test/similar_property.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [property PropertyOne]
  Choice2.        [if PropertyOn]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.property &&
                e.message.contains('"PropertyOn" is not defined') &&
                e.suggestion != null &&
                e.suggestion!.contains('PropertyOne'),
          ),
        ),
      );
    });

    test('throws TslError for else without if', () {
      testFile = File('test/else_without_if.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [else]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.constraint &&
                e.message.contains('requires a preceding "if"') &&
                e.lineNumber == 2 &&
                e.suggestion != null,
          ),
        ),
      );
    });

    test('throws TslError for invalid expression', () {
      testFile = File('test/invalid_expression.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [property PropA]
  Choice2.        [if ]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.expression &&
                e.message.contains('Expression missing') &&
                e.lineNumber == 3 &&
                e.suggestion != null,
          ),
        ),
      );
    });

    test('throws TslError for empty property name', () {
      testFile = File('test/empty_property.tsl');
      testFile.writeAsStringSync('''
# Category
  Choice1.        [property ]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.property &&
                e.message.contains('Property name missing') &&
                e.lineNumber == 2 &&
                e.suggestion != null,
          ),
        ),
      );
    });
  });
}
