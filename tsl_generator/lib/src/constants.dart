/// Constants used by the TSL Generator.
///
/// These constants define limits and flags used throughout the application.
class TslConstants {
  /// Maximum number of total categories allowed.
  static const int maxTotalCategories = 100;

  /// Maximum number of total properties allowed.
  static const int maxTotalProperties = 100;

  /// Maximum length of each category name.
  static const int maxCategoryNameLength = 80;

  /// Maximum number of choices per category.
  static const int maxChoicesPerCategory = 50;

  /// Maximum length of each choice name.
  static const int maxChoiceNameLength = 80;

  /// Maximum number of properties per choice.
  static const int maxPropertiesPerChoice = 10;

  /// Maximum length of each property name.
  static const int maxPropertyNameLength = 32;

  /// Maximum length of temporary strings.
  static const int maxTempStringLength = 256;

  /// The special string representing a "single" frame.
  static const String singleString = "single";

  /// The special string representing an "error" frame.
  static const String errorString = "error";

  /// The "property" keyword.
  static const String propertyKeyword = "property";

  /// The "if" keyword.
  static const String ifKeyword = "if";

  /// The "else" keyword.
  static const String elseKeyword = "else";
}
