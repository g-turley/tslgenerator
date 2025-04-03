import 'dart:io';

import '../constants.dart';
import '../errors/tsl_errors.dart';
import '../models/category.dart';
import '../models/choice.dart';
import '../models/property.dart';
import 'expression_parser.dart';

/// Class for parsing Test Specification Language files or strings.
class TslParser {
  /// Creates a parser for the given [input].
  /// 
  /// The input can be either a [File] object or a [String].
  TslParser(Object input) {
    if (input is File) {
      _inputFile = input;
      _isFileSource = true;
    } else if (input is String) {
      _inputString = input;
      _isFileSource = false;
    } else {
      throw ArgumentError('Input must be either a File or a String');
    }
  }

  /// The source type of the input.
  late bool _isFileSource;
  
  /// The file to parse (when source is a file).
  File? _inputFile;
  
  /// The string content to parse (when source is a string).
  String? _inputString;
  
  /// Returns the source path for error reporting.
  String get sourcePath => _isFileSource 
    ? _inputFile!.path 
    : "(from string)";
    
  /// Returns the file path for external access.
  /// This is used by expression parser to generate error messages.
  String get filePath => sourcePath;
    
  /// Helper method to create a TslError.fromLine with the appropriate source info
  TslError createErrorFromLine({
    required String message,
    required TslErrorType type,
    required int lineNumber,
    int? columnNumber,
    String? suggestion,
    int? spanStart,
    int? spanEnd,
  }) {
    if (_isFileSource) {
      return TslError.fromLine(
        message: message,
        type: type,
        file: _inputFile!,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        suggestion: suggestion,
        spanStart: spanStart,
        spanEnd: spanEnd,
      );
    } else {
      return TslError.fromLine(
        message: message,
        type: type,
        filePath: sourcePath,
        lineMap: _lineMap,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        suggestion: suggestion,
        spanStart: spanStart,
        spanEnd: spanEnd,
      );
    }
  }

  /// Helper method for creating expression errors with appropriate source info
  TslError createExpressionError({
    required String expression,
    required String details,
    int? lineNumber,
    int? columnNumber,
    String? suggestion,
  }) {
    if (_isFileSource) {
      return TslError.expressionError(
        expression: expression,
        details: details,
        file: _inputFile,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        suggestion: suggestion,
      );
    } else {
      // No direct way to use lineMap with expressionError, 
      // so we'll create a standard error
      final message = 'Error in expression "$expression": $details';
      return TslError(
        message: message,
        type: TslErrorType.expression,
        filePath: sourcePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        lineContent: lineNumber != null ? _lineMap[lineNumber] : null,
        suggestion: suggestion,
      );
    }
  }

  /// All categories parsed from the input.
  final List<Category> categories = [];

  /// All properties parsed from the input.
  final Map<String, Property> properties = {};

  /// The maximum category name length, used for formatting output.
  int maxCategoryNameLength = 0;

  /// Maps line numbers to their content for error reporting.
  final Map<int, String> _lineMap = {};
  
  /// The current category being processed.
  Category? _currentCategory;

  /// The current choice being processed.
  Choice? _currentChoice;

  /// Creates a `Property` with the given [name] and adds it to the properties map.
  /// Should only be called for defining new properties.
  Property createProperty(String name, {int? lineNumber}) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw TslError(
        message: 'Property name cannot be empty',
        type: TslErrorType.property,
        filePath: sourcePath,
        lineNumber: lineNumber,
        suggestion: 'Provide a non-empty name for this property',
      );
    }

    if (normalizedName.length > TslConstants.maxPropertyNameLength) {
      throw TslError(
        message:
            'Property name "$normalizedName" exceeds maximum length of ${TslConstants.maxPropertyNameLength} characters',
        type: TslErrorType.property,
        filePath: sourcePath,
        lineNumber: lineNumber,
        suggestion:
            'Use a shorter name (maximum ${TslConstants.maxPropertyNameLength} characters)',
      );
    }

    if (properties.containsKey(normalizedName)) {
      return properties[normalizedName]!;
    } else {
      final property = Property(normalizedName);
      properties[normalizedName] = property;
      return property;
    }
  }

  /// Gets an existing `Property` with the given [name].
  /// Throws an exception if the property does not exist.
  Property getProperty(String name, {int? lineNumber, int? columnNumber}) {
    final normalizedName = name.trim();
    if (!properties.containsKey(normalizedName)) {
      final similarProperties = _findSimilarProperties(normalizedName);
      String suggestion;

      if (similarProperties.isNotEmpty) {
        if (similarProperties.length == 1) {
          suggestion =
              'Did you mean "${similarProperties.first}"? Define the property "$normalizedName" using [property $normalizedName] before using it in an expression, or use the existing property "${similarProperties.first}" instead.';
        } else {
          suggestion =
              'Did you mean one of these properties: ${similarProperties.join(', ')}? Define the property "$normalizedName" using [property $normalizedName] before using it in an expression.';
        }
      } else {
        suggestion =
            'Define the property "$normalizedName" using [property $normalizedName] before using it in an expression';
      }

      throw TslError(
        message: 'The property "$normalizedName" is not defined',
        type: TslErrorType.property,
        filePath: sourcePath,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        lineContent: lineNumber != null ? _lineMap[lineNumber] : null,
        suggestion: suggestion,
      );
    }
    return properties[normalizedName]!;
  }

  /// Finds similar properties to the given [name] for providing suggestions.
  List<String> _findSimilarProperties(String name) {
    if (properties.isEmpty) return [];

    final similarProperties = <String>[];

    // Check for case insensitive matches
    for (final prop in properties.keys) {
      // Check for substring matches (e.g., "PropA" is similar to "PropAB")
      if (prop.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(prop.toLowerCase())) {
        similarProperties.add(prop);
        continue;
      }

      // Check for similar properties with a few characters different
      final similarity = _calculateSimilarity(name, prop);
      if (similarity > 0.6) {
        similarProperties.add(prop);
      }
    }

    return similarProperties;
  }

  /// Calculates a simple similarity score between two strings.
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Convert to lowercase for case-insensitive comparison
    final str1 = s1.toLowerCase();
    final str2 = s2.toLowerCase();

    // Very simple Levenshtein-like distance
    // Count matching characters and positions
    int matchingChars = 0;
    int positionMatches = 0;

    // First check for characters that match by position
    final minLength = str1.length < str2.length ? str1.length : str2.length;
    for (int i = 0; i < minLength; i++) {
      if (str1[i] == str2[i]) {
        matchingChars++;
        positionMatches++;
      }
    }

    // Then check for characters that exist in both strings but not at same position
    final str1Chars = str1.split('')..sort();
    final str2Chars = str2.split('')..sort();

    int i = 0, j = 0;
    while (i < str1Chars.length && j < str2Chars.length) {
      if (str1Chars[i] == str2Chars[j]) {
        matchingChars++;
        i++;
        j++;
      } else if (str1Chars[i].compareTo(str2Chars[j]) < 0) {
        i++;
      } else {
        j++;
      }
    }

    // Give more weight to position matches
    final maxLength = str1.length > str2.length ? str1.length : str2.length;
    return (matchingChars / maxLength * 0.5) +
        (positionMatches / maxLength * 0.5);
  }

  /// Handles comments within constraint lines
  String _removeInlineComments(String line) {
    // Find the position of the first # that isn't inside brackets
    int pos = 0;
    int bracketLevel = 0;
    
    while (pos < line.length) {
      if (line[pos] == '[') {
        bracketLevel++;
      } else if (line[pos] == ']') {
        bracketLevel--;
      } else if (line[pos] == '#' && bracketLevel == 0) {
        // Found a # outside of brackets - this is the start of a comment
        return line.substring(0, pos).trim();
      }
      pos++;
    }
    
    // No comment found
    return line;
  }

  /// Parses the input (file or string) and returns the list of categories.
  List<Category> parse() {
    List<String> lines;
    
    try {
      if (_isFileSource) {
        if (!_inputFile!.existsSync()) {
          throw TslError(
            message: 'Input file does not exist: ${_inputFile!.path}',
            type: TslErrorType.fileSystem,
            suggestion: 'Check that the file exists and the path is correct',
          );
        }
        lines = _inputFile!.readAsLinesSync();
      } else {
        // Split string into lines
        lines = _inputString!.split('\n');
      }
      
      // Store lines for error reporting
      for (var i = 0; i < lines.length; i++) {
        _lineMap[i + 1] = lines[i];
      }

      _currentCategory = null;
      _currentChoice = null;

      for (var i = 0; i < lines.length; i++) {
        final lineNumber = i + 1;
        var line = lines[i].trim();

        // Skip empty lines
        if (line.isEmpty) continue;

        // Remove inline comments
        line = _removeInlineComments(line);
        
        // Skip if the line is empty after removing comments
        if (line.isEmpty) continue;

        // Skip comment lines
        if (line.startsWith('#')) continue;

        // Parse line based on content and context
        _parseLine(line, lineNumber);
      }

      // Filter out categories with no choices
      categories.removeWhere((category) => !category.hasChoices);

      if (categories.isEmpty) {
        throw TslError(
          message: 'No valid categories found in file',
          type: TslErrorType.syntax,
          filePath: sourcePath,
          suggestion:
              'Ensure your file contains at least one category with choices',
        );
      }

      return categories;
    } catch (e) {
      if (e is TslError) {
        rethrow;
      }
      throw TslError(
        message: 'Failed to parse file: ${e.toString()}',
        type: TslErrorType.other,
        filePath: sourcePath,
        suggestion: 'Check file format and syntax',
      );
    }
  }
  
  /// Parses a line based on its content and context.
  void _parseLine(String line, int lineNumber) {
    // Check if it's a category (with colon)
    if (line.endsWith(':')) {
      final categoryName = line.substring(0, line.length - 1).trim();
      _createCategory(categoryName, lineNumber);
      return;
    }

    // Check if it's a choice (contains a period)
    final periodIndex = line.indexOf('.');
    if (periodIndex >= 0) {
      // If there's no current category, that's an error
      if (_currentCategory == null) {
        throw createErrorFromLine(
          message: 'Choice must be preceded by a category',
          type: TslErrorType.syntax,
          lineNumber: lineNumber,
          suggestion:
              'Add a category header (CategoryName:) before this choice',
        );
      }

      // The choice name is everything before the dot
      final choiceName = line.substring(0, periodIndex).trim();
      _createChoice(choiceName, lineNumber);

      // Parse any constraints on the same line
      final constraintText = line.substring(periodIndex + 1).trim();
      if (constraintText.isNotEmpty) {
        _parseConstraintText(constraintText, lineNumber, periodIndex + 1);
      }

      return;
    }

    // If we get here, it might be a constraint line for the current choice
    if (_currentChoice != null && line.contains('[') && line.contains(']')) {
      _parseConstraintText(line, lineNumber, 0);
      return;
    }

    // If none of the above, it's an unrecognized line
    if (line.trim().isNotEmpty) {
      throw createErrorFromLine(
        message: 'Unrecognized line format',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        suggestion: 'Check line format - must be a category, choice, or constraint',
      );
    }
  }
  
  /// Creates a new category with the given name.
  void _createCategory(String categoryName, int lineNumber) {
    if (categoryName.isEmpty) {
      throw createErrorFromLine(
        message: 'Category name cannot be empty',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        suggestion: 'Provide a name for this category',
      );
    }

    if (categoryName.length > TslConstants.maxCategoryNameLength) {
      throw createErrorFromLine(
        message:
            'Category name "$categoryName" exceeds maximum length of ${TslConstants.maxCategoryNameLength} characters',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        spanStart: 0,
        spanEnd: categoryName.length,
        suggestion:
            'Shorten the category name to at most ${TslConstants.maxCategoryNameLength} characters',
      );
    }

    _currentCategory = Category(categoryName);
    if (categoryName.length > maxCategoryNameLength) {
      maxCategoryNameLength = categoryName.length;
    }

    // Add to categories list
    categories.add(_currentCategory!);
    
    // Reset current choice since we're in a new category
    _currentChoice = null;
  }
  
  /// Creates a new choice with the given name.
  void _createChoice(String choiceName, int lineNumber) {
    if (choiceName.isEmpty) {
      throw createErrorFromLine(
        message: 'Choice name cannot be empty',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        suggestion: 'Provide a name for this choice',
      );
    }

    if (choiceName.length > TslConstants.maxChoiceNameLength) {
      throw createErrorFromLine(
        message:
            'Choice name "$choiceName" exceeds maximum length of ${TslConstants.maxChoiceNameLength} characters',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        spanStart: 0,
        spanEnd: choiceName.length,
        suggestion:
            'Shorten the choice name to at most ${TslConstants.maxChoiceNameLength} characters',
      );
    }

    _currentChoice = Choice(choiceName);
    _currentCategory!.addChoice(_currentChoice!);
  }
  
  /// Parses constraint text and adds constraints to the current choice.
  void _parseConstraintText(String constraintText, int lineNumber, int startOffset) {
    if (_currentChoice == null) {
      throw createErrorFromLine(
        message: 'Constraint found but no choice is active',
        type: TslErrorType.syntax,
        lineNumber: lineNumber,
        suggestion: 'Add a choice before defining constraints',
      );
    }

    // Extract constraints in square brackets
    final constraintPattern = RegExp(r'\[(.*?)\]');
    final matches = constraintPattern.allMatches(constraintText);

    // If no valid constraints found but text exists
    if (matches.isEmpty && constraintText.isNotEmpty) {
      // Check if there's any non-whitespace text
      if (constraintText.trim().isNotEmpty) {
        throw createErrorFromLine(
          message:
              'Found text not enclosed in brackets: "${constraintText.trim()}"',
          type: TslErrorType.syntax,
          lineNumber: lineNumber,
          spanStart: startOffset,
          spanEnd: startOffset + constraintText.length,
          suggestion:
              'All constraints must be enclosed in square brackets, e.g., [property Name], [single], [error], etc.',
        );
      }
    }

    // Check between and after matched constraints for unbracketed text
    if (matches.isNotEmpty) {
      int lastEnd = 0;
      for (final match in matches) {
        final start = match.start;

        // Check text between previous constraint and this one
        if (start > lastEnd) {
          final betweenText = constraintText.substring(lastEnd, start).trim();
          if (betweenText.isNotEmpty) {
            throw createErrorFromLine(
              message: 'Found text not enclosed in brackets: "$betweenText"',
              type: TslErrorType.syntax,
              lineNumber: lineNumber,
              spanStart: startOffset + lastEnd,
              spanEnd: startOffset + start,
              suggestion:
                  'All constraints must be enclosed in square brackets, e.g., [property Name], [single], [error], etc.',
            );
          }
        }

        lastEnd = match.end;
      }

      // Check if there's any text after the last constraint
      if (lastEnd < constraintText.length) {
        final afterText = constraintText.substring(lastEnd).trim();
        if (afterText.isNotEmpty) {
          throw createErrorFromLine(
            message: 'Found text not enclosed in brackets: "$afterText"',
            type: TslErrorType.syntax,
            lineNumber: lineNumber,
            spanStart: startOffset + lastEnd,
            spanEnd: startOffset + constraintText.length,
            suggestion:
                'All constraints must be enclosed in square brackets, e.g., [property Name], [single], [error], etc.',
          );
        }
      }
    }

    // Process each constraint
    for (final match in matches) {
      final constraint = match.group(1)?.trim() ?? '';
      final constraintStartPos = startOffset + match.start;
      try {
        parseConstraint(_currentChoice!, constraint, lineNumber, constraintStartPos);
      } catch (e) {
        if (e is TslError) {
          rethrow;
        }
        throw createErrorFromLine(
          message: 'Error parsing constraint: ${e.toString()}',
          type: TslErrorType.constraint,
          lineNumber: lineNumber,
          spanStart: constraintStartPos,
          spanEnd:
              constraintStartPos +
              constraint.length +
              2, // +2 for the [] brackets
          suggestion: 'Check constraint syntax',
        );
      }
    }
  }

  /// Parses a constraint and applies it to the given [choice].
  void parseConstraint(
    Choice choice,
    String constraint,
    int lineNumber,
    int columnNumber,
  ) {
    if (constraint.isEmpty) {
      throw createErrorFromLine(
        message: 'Empty constraint',
        type: TslErrorType.constraint,
        lineNumber: lineNumber,
        columnNumber: columnNumber,
        suggestion: 'Remove empty brackets or add a valid constraint',
      );
    }

    // Check for single/error constraints
    if (constraint == TslConstants.singleString) {
      if (choice.hasElseClause) {
        choice.elseFrameType = FrameType.single;
      } else if (choice.hasIfExpression) {
        choice.ifFrameType = FrameType.single;
      } else {
        choice.frameType = FrameType.single;
      }
      return;
    }

    if (constraint == TslConstants.errorString) {
      if (choice.hasElseClause) {
        choice.elseFrameType = FrameType.error;
      } else if (choice.hasIfExpression) {
        choice.ifFrameType = FrameType.error;
      } else {
        choice.frameType = FrameType.error;
      }
      return;
    }

    // Check for property lists
    if (constraint.startsWith(TslConstants.propertyKeyword)) {
      final propertyText =
          constraint.substring(TslConstants.propertyKeyword.length).trim();
      if (propertyText.isEmpty) {
        throw createErrorFromLine(
          message: 'Property name missing after "property" keyword',
          type: TslErrorType.property,
          lineNumber: lineNumber,
          columnNumber: columnNumber + TslConstants.propertyKeyword.length,
          suggestion:
              'Add a property name after the "property" keyword, e.g., [property MyProperty]',
        );
      }

      final propertyNames = propertyText.split(',');

      for (final name in propertyNames) {
        final trimmedName = name.trim();
        if (trimmedName.isNotEmpty) {
          if (choice.hasElseClause) {
            choice.addElseProperty(
              createProperty(trimmedName, lineNumber: lineNumber),
            );
          } else if (choice.hasIfExpression) {
            choice.addIfProperty(
              createProperty(trimmedName, lineNumber: lineNumber),
            );
          } else {
            choice.addProperty(
              createProperty(trimmedName, lineNumber: lineNumber),
            );
          }
        }
      }

      return;
    }

    // Check for if expressions
    if (constraint.startsWith(TslConstants.ifKeyword)) {
      final expressionText =
          constraint.substring(TslConstants.ifKeyword.length).trim();
      if (expressionText.isEmpty) {
        throw createErrorFromLine(
          message: 'Expression missing after "if" keyword',
          type: TslErrorType.expression,
          lineNumber: lineNumber,
          columnNumber: columnNumber + TslConstants.ifKeyword.length,
          suggestion:
              'Add a logical expression after the "if" keyword, e.g., [if PropertyName]',
        );
      }

      try {
        final expressionParser = ExpressionParser(this);
        choice.ifExpression = expressionParser.parse(
          expressionText,
          lineNumber: lineNumber,
          columnOffset: columnNumber + TslConstants.ifKeyword.length,
        );
      } catch (e) {
        if (e is TslError) {
          rethrow;
        }
        throw createExpressionError(
          expression: expressionText,
          details: e.toString(),
          lineNumber: lineNumber,
          columnNumber: columnNumber + TslConstants.ifKeyword.length,
          suggestion:
              'Check that all properties in the expression are defined and the expression syntax is correct',
        );
      }
      return;
    }

    // Check for else clauses
    if (constraint == TslConstants.elseKeyword) {
      if (!choice.hasIfExpression) {
        throw createErrorFromLine(
          message: '"else" constraint requires a preceding "if" constraint',
          type: TslErrorType.constraint,
          lineNumber: lineNumber,
          columnNumber: columnNumber,
          suggestion:
              'Add an "if" constraint before using "else", or remove the "else" constraint',
        );
      }
      choice.hasElseClause = true;
      return;
    }

    throw createErrorFromLine(
      message: 'Unknown constraint: $constraint',
      type: TslErrorType.constraint,
      lineNumber: lineNumber,
      columnNumber: columnNumber,
      suggestion:
          'Valid constraints are: "single", "error", "property", "if", and "else"',
    );
  }
}