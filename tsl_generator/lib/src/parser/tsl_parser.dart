import 'dart:io';

import '../constants.dart';
import '../errors/tsl_errors.dart';
import '../models/category.dart';
import '../models/choice.dart';
import '../models/property.dart';
import 'expression_parser.dart';

/// Class for parsing Test Specification Language files.
class TslParser {
  /// Creates a parser for the given [inputFile].
  TslParser(this.inputFile);

  /// The file to parse.
  final File inputFile;

  /// All categories parsed from the file.
  final List<Category> categories = [];

  /// All properties parsed from the file.
  final Map<String, Property> properties = {};

  /// The maximum category name length, used for formatting output.
  int maxCategoryNameLength = 0;

  /// Maps line numbers to their content for error reporting.
  final Map<int, String> _lineMap = {};

  /// Creates a `Property` with the given [name] and adds it to the properties map.
  /// Should only be called for defining new properties.
  Property createProperty(String name, {int? lineNumber}) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw TslError(
        message: 'Property name cannot be empty',
        type: TslErrorType.property,
        filePath: inputFile.path,
        lineNumber: lineNumber,
        suggestion: 'Provide a non-empty name for this property',
      );
    }

    if (normalizedName.length > TslConstants.maxPropertyNameLength) {
      throw TslError(
        message:
            'Property name "$normalizedName" exceeds maximum length of ${TslConstants.maxPropertyNameLength} characters',
        type: TslErrorType.property,
        filePath: inputFile.path,
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
        filePath: inputFile.path,
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

  /// Parses the input file and returns the list of categories.
  List<Category> parse() {
    if (!inputFile.existsSync()) {
      throw TslError(
        message: 'Input file does not exist: ${inputFile.path}',
        type: TslErrorType.fileSystem,
        suggestion: 'Check that the file exists and the path is correct',
      );
    }

    try {
      final lines = inputFile.readAsLinesSync();
      // Store lines for error reporting
      for (var i = 0; i < lines.length; i++) {
        _lineMap[i + 1] = lines[i];
      }

      Category? currentCategory;

      for (var i = 0; i < lines.length; i++) {
        final lineNumber = i + 1;
        final line = lines[i].trim();

        // Skip empty lines
        if (line.isEmpty) continue;

        // Skip comment lines (lines starting with # but don't treat category headers as comments)
        if (line.startsWith('#') && !_isCategoryHeader(line)) continue;

        // Parse category or choice
        if (_isCategoryHeader(line)) {
          // It's a category header
          final categoryName = _extractCategoryName(line);
          if (categoryName.isEmpty) {
            throw TslError.fromLine(
              message: 'Category name cannot be empty',
              type: TslErrorType.syntax,
              file: inputFile,
              lineNumber: lineNumber,
              suggestion: 'Provide a name for this category',
            );
          }

          if (categoryName.length > TslConstants.maxCategoryNameLength) {
            throw TslError.fromLine(
              message:
                  'Category name "$categoryName" exceeds maximum length of ${TslConstants.maxCategoryNameLength} characters',
              type: TslErrorType.syntax,
              file: inputFile,
              lineNumber: lineNumber,
              spanStart: 1, // Skip the # character
              spanEnd: categoryName.length + 1, // +1 for the # character
              suggestion:
                  'Shorten the category name to at most ${TslConstants.maxCategoryNameLength} characters',
            );
          }

          currentCategory = Category(categoryName);
          if (categoryName.length > maxCategoryNameLength) {
            maxCategoryNameLength = categoryName.length;
          }

          // Add to categories list
          categories.add(currentCategory);
        } else if (line.endsWith(':')) {
          // It's a subcategory
          final categoryName = line.substring(0, line.length - 1).trim();
          if (categoryName.isEmpty) {
            throw TslError.fromLine(
              message: 'Category name cannot be empty',
              type: TslErrorType.syntax,
              file: inputFile,
              lineNumber: lineNumber,
              suggestion: 'Provide a name for this category',
            );
          }

          if (categoryName.length > TslConstants.maxCategoryNameLength) {
            throw TslError.fromLine(
              message:
                  'Category name "$categoryName" exceeds maximum length of ${TslConstants.maxCategoryNameLength} characters',
              type: TslErrorType.syntax,
              file: inputFile,
              lineNumber: lineNumber,
              spanStart: 0,
              spanEnd: categoryName.length,
              suggestion:
                  'Shorten the category name to at most ${TslConstants.maxCategoryNameLength} characters',
            );
          }

          currentCategory = Category(categoryName);
          if (categoryName.length > maxCategoryNameLength) {
            maxCategoryNameLength = categoryName.length;
          }

          // Add to categories list
          categories.add(currentCategory);
        } else if (line.contains('.')) {
          // It's a choice
          if (currentCategory == null) {
            throw TslError.fromLine(
              message: 'Choice must be preceded by a category',
              type: TslErrorType.syntax,
              file: inputFile,
              lineNumber: lineNumber,
              suggestion:
                  'Add a category header (# CategoryName) before this choice',
            );
          }

          _parseChoiceLine(line, currentCategory, lineNumber);
        }
      }

      // Filter out categories with no choices
      categories.removeWhere((category) => !category.hasChoices);

      if (categories.isEmpty) {
        throw TslError(
          message: 'No valid categories found in file',
          type: TslErrorType.syntax,
          filePath: inputFile.path,
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
        filePath: inputFile.path,
        suggestion: 'Check file format and syntax',
      );
    }
  }

  /// Checks if a line is a category header (starts with #).
  bool _isCategoryHeader(String line) {
    return line.startsWith('#');
  }

  /// Extracts the category name from a header line.
  String _extractCategoryName(String line) {
    // Remove the # and any trailing :
    return line.substring(1).replaceAll(':', '').trim();
  }

  /// Parse a choice line and add it to the given category.
  void _parseChoiceLine(String line, Category category, int lineNumber) {
    // Split the line into the choice name and potential constraints
    final periodIndex = line.indexOf('.');
    if (periodIndex == -1) {
      throw TslError.fromLine(
        message: 'Invalid choice format: missing period',
        type: TslErrorType.syntax,
        file: inputFile,
        lineNumber: lineNumber,
        suggestion:
            'Each choice must end with a period followed by optional constraints',
      );
    }

    // The choice name is everything before the dot
    final choiceName = line.substring(0, periodIndex + 1).trim();
    if (choiceName.isEmpty) {
      throw TslError.fromLine(
        message: 'Choice name cannot be empty',
        type: TslErrorType.syntax,
        file: inputFile,
        lineNumber: lineNumber,
        suggestion: 'Provide a name for this choice',
      );
    }

    if (choiceName.length > TslConstants.maxChoiceNameLength) {
      throw TslError.fromLine(
        message:
            'Choice name "$choiceName" exceeds maximum length of ${TslConstants.maxChoiceNameLength} characters',
        type: TslErrorType.syntax,
        file: inputFile,
        lineNumber: lineNumber,
        spanStart: 0,
        spanEnd: choiceName.length,
        suggestion:
            'Shorten the choice name to at most ${TslConstants.maxChoiceNameLength} characters',
      );
    }

    final choice = Choice(choiceName);

    // Parse the remainder of the line for constraints
    final constraintText = line.substring(periodIndex + 1).trim();

    // Extract constraints in square brackets
    final constraintPattern = RegExp(r'\[(.*?)\]');
    final matches = constraintPattern.allMatches(constraintText);

    if (matches.isEmpty && constraintText.isNotEmpty) {
      throw TslError.fromLine(
        message: 'Invalid constraint format',
        type: TslErrorType.syntax,
        file: inputFile,
        lineNumber: lineNumber,
        spanStart: periodIndex + 1,
        spanEnd: line.length,
        suggestion:
            'Constraints must be enclosed in square brackets, e.g., [property Name]',
      );
    }

    for (final match in matches) {
      final constraint = match.group(1)?.trim() ?? '';
      final constraintStartPos = periodIndex + 1 + match.start;
      try {
        parseConstraint(choice, constraint, lineNumber, constraintStartPos);
      } catch (e) {
        if (e is TslError) {
          rethrow;
        }
        throw TslError.fromLine(
          message: 'Error parsing constraint: ${e.toString()}',
          type: TslErrorType.constraint,
          file: inputFile,
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

    category.addChoice(choice);
  }

  /// Parses a constraint and applies it to the given [choice].
  void parseConstraint(
    Choice choice,
    String constraint,
    int lineNumber,
    int columnNumber,
  ) {
    if (constraint.isEmpty) {
      throw TslError.fromLine(
        message: 'Empty constraint',
        type: TslErrorType.constraint,
        file: inputFile,
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
        throw TslError.fromLine(
          message: 'Property name missing after "property" keyword',
          type: TslErrorType.property,
          file: inputFile,
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
        throw TslError.fromLine(
          message: 'Expression missing after "if" keyword',
          type: TslErrorType.expression,
          file: inputFile,
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
        throw TslError.expressionError(
          expression: expressionText,
          details: e.toString(),
          file: inputFile,
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
        throw TslError.fromLine(
          message: '"else" constraint requires a preceding "if" constraint',
          type: TslErrorType.constraint,
          file: inputFile,
          lineNumber: lineNumber,
          columnNumber: columnNumber,
          suggestion:
              'Add an "if" constraint before using "else", or remove the "else" constraint',
        );
      }
      choice.hasElseClause = true;
      return;
    }

    throw TslError.fromLine(
      message: 'Unknown constraint: $constraint',
      type: TslErrorType.constraint,
      file: inputFile,
      lineNumber: lineNumber,
      columnNumber: columnNumber,
      suggestion:
          'Valid constraints are: "single", "error", "property", "if", and "else"',
    );
  }
}
