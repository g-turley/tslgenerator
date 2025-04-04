import 'dart:io';
import 'dart:math';

/// Types of errors that can occur when working with TSL files.
enum TslErrorType {
  /// Error in the syntax of a TSL file
  syntax,

  /// Error in the logic of a specification
  logic,

  /// Error related to file handling
  fileSystem,

  /// Error in property usage
  property,

  /// Error in expression evaluation
  expression,

  /// Errors related to constraints
  constraint,

  /// Other errors that don't fit into the categories above
  other,
}

/// Class representing a TSL error with enhanced information.
class TslError implements Exception {
  /// Creates a new error with the given [message] and [type].
  TslError({
    required this.message,
    required this.type,
    this.filePath,
    this.lineNumber,
    this.columnNumber,
    this.lineContent,
    this.suggestion,
    this.errorSpan,
  });

  /// The error message explaining what went wrong.
  final String message;

  /// The type of the error.
  final TslErrorType type;

  /// Optional path to the file where the error occurred.
  final String? filePath;

  /// Optional line number where the error occurred (1-based).
  final int? lineNumber;

  /// Optional column number where the error occurred (1-based).
  final int? columnNumber;

  /// Optional content of the line where the error occurred.
  final String? lineContent;

  /// Optional suggestion for fixing the error.
  final String? suggestion;

  /// Optional error span (start:end) for highlighting the error location.
  final String? errorSpan;

  /// Creates a TslError from a line in either a file or a string.
  /// 
  /// This factory accepts either a File object or a filePath string and lineMap,
  /// allowing it to work with both file-based and string-based sources.
  factory TslError.fromLine({
    required String message,
    required TslErrorType type,
    File? file,
    String? filePath,
    Map<int, String>? lineMap,
    required int lineNumber,
    int? columnNumber,
    String? suggestion,
    int? spanStart,
    int? spanEnd,
  }) {
    assert(file != null || (filePath != null && lineMap != null),
        'Either file or filePath+lineMap must be provided');
    
    String? lineContent;
    String? errorSpan;
    String resolvedFilePath;

    if (file != null) {
      resolvedFilePath = file.path;
      try {
        final lines = file.readAsLinesSync();
        if (lineNumber > 0 && lineNumber <= lines.length) {
          lineContent = lines[lineNumber - 1];
        }
      } catch (_) {
        // If we can't read the file, continue without line content
      }
    } else {
      resolvedFilePath = filePath!;
      lineContent = lineMap![lineNumber];
    }

    if (lineContent != null) {
      final match = RegExp(r'^\s*').firstMatch(lineContent);
       int columnStartingWhitespace = match?.group(0)?.length ?? 0;
      if (spanStart != null && spanEnd != null) {
        final start = max(0, spanStart);
        final end = min(lineContent.length, spanEnd);

        if (start < end) {
          // Create error span for highlighting
          errorSpan = ' ' * (start + columnStartingWhitespace) + '^' * (end - start);
        }
      } else if (columnNumber != null) {
        // Just highlight the column position
        errorSpan = '${' ' * (columnNumber - 1 + columnStartingWhitespace)}^';
      }
    }

    return TslError(
      message: message,
      type: type,
      filePath: resolvedFilePath,
      lineNumber: lineNumber,
      columnNumber: columnNumber,
      lineContent: lineContent,
      suggestion: suggestion,
      errorSpan: errorSpan,
    );
  }

  /// Creates a property-related error.
  factory TslError.propertyError({
    required String propertyName,
    String? suggestion,
    File? file,
    int? lineNumber,
  }) {
    final message = 'The property "$propertyName" is not defined';
    final fullSuggestion =
        suggestion ??
        'Define the property "$propertyName" using [property $propertyName] before using it in an expression';

    if (file != null && lineNumber != null) {
      return TslError.fromLine(
        message: message,
        type: TslErrorType.property,
        file: file,
        lineNumber: lineNumber,
        suggestion: fullSuggestion,
      );
    }

    return TslError(
      message: message,
      type: TslErrorType.property,
      suggestion: fullSuggestion,
    );
  }

  /// Creates an expression-related error.
  factory TslError.expressionError({
    required String expression,
    required String details,
    String? suggestion,
    File? file,
    int? lineNumber,
    int? columnNumber,
  }) {
    final message = 'Error in expression "$expression": $details';

    if (file != null && lineNumber != null) {
      return TslError.fromLine(
        message: message,
        type: TslErrorType.expression,
        file: file,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        suggestion: suggestion,
      );
    }

    return TslError(
      message: message,
      type: TslErrorType.expression,
      suggestion: suggestion,
    );
  }

  /// Format the error as a user-friendly string.
  @override
  String toString() {
    final buffer = StringBuffer();

    // Add error type and message
    buffer.writeln('Error: ${type.name}: $message');

    // Add file location information if available
    if (filePath != null) {
      buffer.write('  at $filePath');
      if (lineNumber != null) {
        buffer.write(':$lineNumber');
        if (columnNumber != null) {
          buffer.write(':$columnNumber');
        }
      }
      buffer.writeln();
    }

    // Add line content and error span if available
    if (lineContent != null) {
      buffer.writeln('  | $lineContent');
      if (errorSpan != null) {
        buffer.writeln('  | $errorSpan');
      }
    }

    // Add suggestion if available
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }

    return buffer.toString();
  }
}
