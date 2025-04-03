import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/src/errors/tsl_errors.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('Unbracketed Constraint Detection', () {
    late File testFile;

    tearDown(() {
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('detects unbracketed "error" constraint', () {
      testFile = File('test/unbracketed_error.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. [if !(x || y)] error [else]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "error"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects unbracketed "single" constraint', () {
      testFile = File('test/unbracketed_single.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. [property A] single [property B]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "single"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects unbracketed "if" constraint', () {
      testFile = File('test/unbracketed_if.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. if A && B [property C]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "if A && B"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects unbracketed "else" constraint', () {
      testFile = File('test/unbracketed_else.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. [if A] [property B] else
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "else"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects unbracketed "property" constraint', () {
      testFile = File('test/unbracketed_property.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. property A [if B]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "property A"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects random text between constraints', () {
      testFile = File('test/random_text.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. [if A] some random text [property B]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "some random text"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('detects random text after constraints', () {
      testFile = File('test/after_text.tsl');
      testFile.writeAsStringSync('''
Category:
  Choice1. [if A] [property B] some trailing text
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "some trailing text"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });

    test('handles common error case with original example', () {
      testFile = File('test/original_case.tsl');
      testFile.writeAsStringSync('''
Option:
        Set. [if !(bad || anotha)] error [else]
        Unset. [property anotha]
''');

      final parser = TslParser(testFile);

      expect(
        () => parser.parse(),
        throwsA(
          predicate<TslError>(
            (e) =>
                e.type == TslErrorType.syntax &&
                e.message.contains(
                  'Found text not enclosed in brackets: "error"',
                ) &&
                e.suggestion != null &&
                e.suggestion!.contains(
                  'All constraints must be enclosed in square brackets',
                ),
          ),
        ),
      );
    });
  });
}
