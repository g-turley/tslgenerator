import 'dart:io';

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
    // Create a temporary file
    final tempDir = Directory.systemTemp.createTempSync('tsl_generator_');
    final tempFile = File('${tempDir.path}/temp.tsl');
    tempFile.writeAsStringSync(content);

    try {
      return TslSpecification.fromTslFile(tempFile);
    } finally {
      // Clean up
      tempFile.deleteSync();
      tempDir.deleteSync();
    }
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
    if (_properties.containsKey(name)) {
      return _properties[name]!;
    } else {
      final property = Property(name, value: value);
      _properties[name] = property;
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
