import 'dart:io';

import '../constants.dart';
import '../models/category.dart';
import '../models/choice.dart';
import '../models/property.dart';
import '../models/expression.dart';
import 'expression_parser.dart';

/// Exception thrown when parsing TSL files.
class TslParserException implements Exception {
  /// Creates a new parser exception with the given [message].
  TslParserException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'TslParserException: $message';
}

/// Parses Test Specification Language files.
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

  /// Creates a `Property` with the given [name] and adds it to the properties map.
  /// Should only be called for defining new properties.
  Property createProperty(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw TslParserException('Property name cannot be empty');
    }

    if (normalizedName.length > TslConstants.maxPropertyNameLength) {
      throw TslParserException(
        'Property name "$normalizedName" exceeds maximum length of '
        '${TslConstants.maxPropertyNameLength} characters',
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
  Property getProperty(String name) {
    final normalizedName = name.trim();
    if (!properties.containsKey(normalizedName)) {
      throw TslParserException('The property "$normalizedName" is not defined');
    }
    return properties[normalizedName]!;
  }

  /// Parses the input file and returns the list of categories.
  List<Category> parse() {
    if (!inputFile.existsSync()) {
      throw TslParserException('Input file does not exist: ${inputFile.path}');
    }

    final lines = inputFile.readAsLinesSync();

    Category? currentCategory;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) continue;

      // Skip comment lines
      if (line.startsWith('#')) continue;

      // Parse category or choice
      if (line.endsWith(':')) {
        // It's a category
        final categoryName = line.substring(0, line.length - 1).trim();
        if (categoryName.isEmpty) {
          throw TslParserException(
            'Category name cannot be empty (line ${i + 1})',
          );
        }

        if (categoryName.length > TslConstants.maxCategoryNameLength) {
          throw TslParserException(
            'Category name "$categoryName" exceeds maximum length of '
            '${TslConstants.maxCategoryNameLength} characters (line ${i + 1})',
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
          throw TslParserException(
            'Choice must be preceded by a category (line ${i + 1})',
          );
        }

        // Split the line into the choice name and potential constraints
        final choiceParts = line.split('.');
        if (choiceParts.isEmpty) {
          throw TslParserException('Invalid choice format (line ${i + 1})');
        }

        // The choice name is everything before the last dot
        final choiceName =
            ('${choiceParts.sublist(0, choiceParts.length - 1).join('.')}.')
                .trim();
        if (choiceName.isEmpty) {
          throw TslParserException(
            'Choice name cannot be empty (line ${i + 1})',
          );
        }

        if (choiceName.length > TslConstants.maxChoiceNameLength) {
          throw TslParserException(
            'Choice name "$choiceName" exceeds maximum length of '
            '${TslConstants.maxChoiceNameLength} characters (line ${i + 1})',
          );
        }

        final choice = Choice(choiceName);

        // Parse the remainder of the line for constraints
        final constraintText = choiceParts.last.trim();

        // Extract constraints in square brackets
        final constraintPattern = RegExp(r'\[(.*?)\]');
        final matches = constraintPattern.allMatches(constraintText);

        for (final match in matches) {
          final constraint = match.group(1)?.trim() ?? '';
          parseConstraint(choice, constraint);
        }

        currentCategory.addChoice(choice);
      }
    }

    // Filter out categories with no choices
    categories.removeWhere((category) => !category.hasChoices);

    return categories;
  }

  /// Parses a constraint and applies it to the given [choice].
  void parseConstraint(Choice choice, String constraint) {
    if (constraint.isEmpty) return;

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
      final propertyNames = propertyText.split(',');

      for (final name in propertyNames) {
        final trimmedName = name.trim();
        if (trimmedName.isNotEmpty) {
          if (choice.hasElseClause) {
            choice.addElseProperty(createProperty(trimmedName));
          } else if (choice.hasIfExpression) {
            choice.addIfProperty(createProperty(trimmedName));
          } else {
            choice.addProperty(createProperty(trimmedName));
          }
        }
      }

      return;
    }

    // Check for if expressions
    if (constraint.startsWith(TslConstants.ifKeyword)) {
      final expressionText =
          constraint.substring(TslConstants.ifKeyword.length).trim();
      choice.ifExpression = ExpressionParser(this).parse(expressionText);
      return;
    }

    // Check for else clauses
    if (constraint == TslConstants.elseKeyword) {
      choice.hasElseClause = true;
      return;
    }

    throw TslParserException('Unknown constraint: $constraint');
  }
}
