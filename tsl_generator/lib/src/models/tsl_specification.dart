import 'dart:io';

import 'package:tsl_generator/src/models/choice.dart';
import 'package:tsl_generator/src/models/expression.dart';

import '../errors/tsl_errors.dart';
import '../parser/tsl_parser.dart';
import 'category.dart';
import 'property.dart';

/// A complete TSL specification containing categories and properties.
///
/// This is the main class for working with TSL specifications. It provides
/// methods for building specifications programmatically or parsing them
/// from files, as well as accessing and manipulating the contained data.
class TslSpecification {
  /// Creates an empty TSL specification.
  TslSpecification();

  /// Creates a TSL specification from an existing list of [categories].
  TslSpecification.fromCategories(List<Category> categories) {
    this.categories.addAll(categories);

    // Extract properties from the categories
    for (final category in categories) {
      for (final choice in category.choices) {
        for (final property in choice.properties) {
          _properties[property.name] = property;
        }
        for (final property in choice.ifProperties) {
          _properties[property.name] = property;
        }
        for (final property in choice.elseProperties) {
          _properties[property.name] = property;
        }
      }
    }
  }

  /// Parses a TSL specification from the given [filePath].
  ///
  /// This is a convenience factory method that handles the file I/O
  /// and parsing for you.
  factory TslSpecification.fromFile(String filePath) {
    final file = File(filePath);
    return TslSpecification.fromTslFile(file);
  }

  /// Parses a TSL specification from the given [file].
  factory TslSpecification.fromTslFile(File file) {
    final parser = TslParser(file);
    final categories = parser.parse();
    final spec = TslSpecification();

    // Add categories from parser
    spec.categories.addAll(categories);

    // Add properties from parser
    spec._properties.addAll(parser.properties);

    return spec;
  }

  /// Parses a TSL specification from a string [content].
  ///
  /// This method is useful for testing or when the TSL content
  /// is available as a string rather than a file.
  factory TslSpecification.fromString(String content) {
    final parser = TslParser(content);
    final categories = parser.parse();
    final spec = TslSpecification();

    // Add categories from parser
    spec.categories.addAll(categories);

    // Add properties from parser
    spec._properties.addAll(parser.properties);

    return spec;
  }

  /// All categories in this specification.
  final List<Category> categories = [];

  /// All properties in this specification, mapped by name.
  final Map<String, Property> _properties = {};

  /// Returns a read-only view of the properties in this specification.
  Map<String, Property> get properties => Map.unmodifiable(_properties);

  /// Adds a category to this specification.
  void addCategory(Category category) {
    categories.add(category);

    // Extract properties from the category
    for (final choice in category.choices) {
      for (final property in choice.properties) {
        _properties[property.name] = property;
      }
      for (final property in choice.ifProperties) {
        _properties[property.name] = property;
      }
      for (final property in choice.elseProperties) {
        _properties[property.name] = property;
      }
    }
  }

  /// Creates a new property with the given [name] and optional [value].
  ///
  /// Returns the created property, or the existing property if one
  /// with the same name already exists.
  Property createProperty(String name, {bool value = false}) {
    final normalizedName = name.trim();
    if (_properties.containsKey(normalizedName)) {
      return _properties[normalizedName]!;
    } else {
      final property = Property(normalizedName, value: value);
      _properties[normalizedName] = property;
      return property;
    }
  }

  /// Gets a property by [name]. Returns null if the property doesn't exist.
  Property? getProperty(String name) {
    return _properties[name];
  }

  /// Gets a property by [name], or creates it if it doesn't exist.
  Property getOrCreateProperty(String name, {bool value = false}) {
    if (_properties.containsKey(name)) {
      return _properties[name]!;
    } else {
      final property = Property(name, value: value);
      _properties[name] = property;
      return property;
    }
  }

  /// Sets the value of a property by [name].
  ///
  /// Creates the property if it doesn't exist.
  void setPropertyValue(String name, bool value) {
    getOrCreateProperty(name).value = value;
  }

  /// Resets all properties to their default value (false).
  void resetAllProperties() {
    for (final property in _properties.values) {
      property.value = false;
    }
  }

  /// Converts this specification to a TSL string representation.
  /// This is useful for validation and debugging.
  String toTslString() {
    final buffer = StringBuffer();
    
    // Add all categories
    for (final category in categories) {
      buffer.writeln('${category.name}:');
      
      // Add all choices
      for (final choice in category.choices) {
        buffer.write('  ${choice.name}.');
        
        // Add constraints for this choice
        
        // Add if expression if present
        if (choice.ifExpression != null) {
          buffer.write(' [if ${_expressionToString(choice.ifExpression!)}]');
        }
        
        // Add properties
        for (final property in choice.properties) {
          buffer.write(' [property ${property.name}]');
        }
        
        // Add if properties if present
        if (choice.ifProperties.isNotEmpty && choice.hasIfExpression) {
          for (final property in choice.ifProperties) {
            buffer.write(' [property ${property.name}]');
          }
        }
        
        // Add else clause if present
        if (choice.hasElseClause) {
          buffer.write(' [else]');
          
          // Add else properties
          for (final property in choice.elseProperties) {
            buffer.write(' [property ${property.name}]');
          }
        }
        
        // Add frame type if not normal
        if (choice.frameType == FrameType.single) {
          buffer.write(' [single]');
        } else if (choice.frameType == FrameType.error) {
          buffer.write(' [error]');
        }
        
        // Add if frame type if not normal
        if (choice.hasIfExpression && choice.ifFrameType != FrameType.normal) {
          if (choice.ifFrameType == FrameType.single) {
            buffer.write(' [if] [single]');
          } else if (choice.ifFrameType == FrameType.error) {
            buffer.write(' [if] [error]');
          }
        }
        
        // Add else frame type if not normal
        if (choice.hasElseClause && choice.elseFrameType != FrameType.normal) {
          if (choice.elseFrameType == FrameType.single) {
            buffer.write(' [else] [single]');
          } else if (choice.elseFrameType == FrameType.error) {
            buffer.write(' [else] [error]');
          }
        }
        
        buffer.writeln();
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Converts an expression to a string representation.
  String _expressionToString(Expression expr) {
    final buffer = StringBuffer();
    
    // Left operand
    if (expr.notA) {
      buffer.write('!');
    }
    
    if (expr.isExprA) {
      // Nested expression
      buffer.write('(${_expressionToString(expr.exprA!)})');
    } else if (expr.propA != null) {
      // Property
      buffer.write(expr.propA!.name);
    }
    
    // Operator
    if (expr.operatorType == OperatorType.and) {
      buffer.write(' && ');
    } else {
      buffer.write(' || ');
    }
    
    // Right operand (if not a dummy prop 'F')
    if (expr.propB != null && expr.propB!.name == 'F') {
      // This is a single-operand expression
      return buffer.toString().substring(0, buffer.length - 4);
    }
    
    if (expr.notB) {
      buffer.write('!');
    }
    
    if (expr.isExprB) {
      // Nested expression
      buffer.write('(${_expressionToString(expr.exprB!)})');
    } else if (expr.propB != null) {
      // Property
      buffer.write(expr.propB!.name);
    }
    
    return buffer.toString();
  }

  /// Validates that all referenced properties are defined by converting
  /// to a TSL string and parsing it with the TslParser.
  ///
  /// This takes advantage of the existing validation in the parser.
  void validate() {
    // Convert to TSL string
    final tslString = toTslString();
    
    // Parse the string to trigger validation
    final parser = TslParser(tslString);
    
    try {
      parser.parse();
      // Parsing succeeded, which means validation passed
    } catch (e) {
      // Re-throw parsing errors
      rethrow;
    }
  }

  /// Returns the maximum category name length, useful for formatting output.
  int get maxCategoryNameLength {
    if (categories.isEmpty) return 0;
    return categories
        .map((c) => c.name.length)
        .reduce((max, length) => length > max ? length : max);
  }

  /// Returns the number of choices across all categories.
  int get totalChoicesCount {
    return categories.fold(0, (sum, category) => sum + category.choices.length);
  }

  /// Returns whether this specification is empty (has no categories).
  bool get isEmpty => categories.isEmpty;

  /// Returns whether this specification is not empty (has at least one category).
  bool get isNotEmpty => categories.isNotEmpty;
}