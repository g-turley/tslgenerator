import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/src/errors/tsl_errors.dart';

void main() {
  group('TslError', () {
    test('creates basic error with minimal information', () {
      final error = TslError(
        message: 'Test error message',
        type: TslErrorType.syntax,
      );

      expect(error.message, equals('Test error message'));
      expect(error.type, equals(TslErrorType.syntax));
      expect(error.toString(), contains('Error: syntax: Test error message'));
    });

    test('creates error with full information', () {
      final error = TslError(
        message: 'Test error message',
        type: TslErrorType.property,
        filePath: 'test.tsl',
        lineNumber: 42,
        columnNumber: 10,
        lineContent: 'Property test line',
        suggestion: 'Fix the property',
        errorSpan: '         ^',
      );

      final errorString = error.toString();
      expect(errorString, contains('Error: property: Test error message'));
      expect(errorString, contains('at test.tsl:42:10'));
      expect(errorString, contains('| Property test line'));
      expect(errorString, contains('|          ^'));
      expect(errorString, contains('Suggestion: Fix the property'));
    });

    test('creates property error with suggestion', () {
      final error = TslError.propertyError(
        propertyName: 'TestProp',
        suggestion: 'Define TestProp first',
      );

      expect(error.message, contains('TestProp'));
      expect(error.type, equals(TslErrorType.property));
      expect(error.suggestion, equals('Define TestProp first'));
    });

    test('creates expression error with details', () {
      final error = TslError.expressionError(
        expression: 'A && B',
        details: 'Property B not found',
        suggestion: 'Define property B',
      );

      expect(error.message, contains('A && B'));
      expect(error.message, contains('Property B not found'));
      expect(error.type, equals(TslErrorType.expression));
      expect(error.suggestion, equals('Define property B'));
    });

    test('creates error with line information from file', () {
      // Create a temporary test file
      final tempFile = File('test/temp_error_test.tsl');
      tempFile.writeAsStringSync('''
# Test TSL File
Category:
  Choice1. [property ]''');

      try {
        // Test error creation from file line
        final error = TslError.fromLine(
          message: 'Test line error',
          type: TslErrorType.syntax,
          file: tempFile,
          lineNumber: 3,
          columnNumber: 12,
          suggestion: 'Fix the error',
        );

        expect(error.lineContent, equals('  Choice1. [property ]'));
        expect(error.errorSpan, equals('             ^'));

        // Test with span
        final spanError = TslError.fromLine(
          message: 'Test span error',
          type: TslErrorType.syntax,
          file: tempFile,
          lineNumber: 3,
          spanStart: 11,
          spanEnd: 16,
          suggestion: 'Fix the span',
        );

        expect(spanError.lineContent, equals('  Choice1. [property ]'));
        expect(spanError.errorSpan, equals('             ^^^^^'));
      } finally {
        // Clean up
        tempFile.deleteSync();
      }
    });
  });
}
