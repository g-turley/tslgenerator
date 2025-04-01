import 'category.dart';
import 'choice.dart';

/// Represents a test frame that is generated from a TSL specification.
///
/// A test frame can be a normal test frame with multiple categories and choices,
/// or a single/error frame with just one category and choice.
class TestFrame {
  /// Creates a test frame with the given [number].
  TestFrame(this.number);

  /// The test frame number (sequential).
  final int number;

  /// The categories and choices in this test frame.
  final Map<Category, Choice?> categoriesAndChoices = {};

  /// The key string representing the selections in this frame (e.g., "1.2.3").
  String key = "";

  /// The frame type (normal, single, or error).
  FrameType frameType = FrameType.normal;

  /// Whether this frame is generated from an if/else clause.
  bool fromIfElse = false;

  /// The if/else branch used, if this is from an if/else clause.
  String? ifElseBranch;

  /// Sets the category and choice for a single/error frame.
  void setSingleFrame(
    Category category,
    Choice choice,
    FrameType type, {
    String? branchType,
  }) {
    categoriesAndChoices[category] = choice;
    frameType = type;
    if (branchType != null) {
      fromIfElse = true;
      ifElseBranch = branchType;
    }
  }

  /// Adds a category and choice to this test frame.
  void addCategoryAndChoice(Category category, Choice? choice) {
    categoriesAndChoices[category] = choice;
  }

  /// Sets the key string for this test frame.
  void setKey(String frameKey) {
    key = frameKey;
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write("Test Case ${number.toString().padRight(3)}");

    if (frameType != FrameType.normal) {
      buffer.write("\t\t<${frameType.toString()}>");
      if (fromIfElse && ifElseBranch != null) {
        buffer.write("  (follows [$ifElseBranch])");
      }
      buffer.writeln();

      // Only one entry for single/error frames
      final entry = categoriesAndChoices.entries.first;
      buffer.write("   ${entry.key.name} :  ${entry.value?.name ?? '<n/a>'}");
      buffer.writeln();
    } else {
      buffer.write("\t\t(Key = $key)");
      buffer.writeln();

      // Find the longest category name for alignment
      final maxCategoryNameLength = categoriesAndChoices.keys
          .map((c) => c.name.length)
          .fold(0, (max, length) => length > max ? length : max);

      // Write all categories and choices
      for (final entry in categoriesAndChoices.entries) {
        buffer.write(
          "   ${entry.key.name.padRight(maxCategoryNameLength)} :  ${entry.value?.name ?? '<n/a>'}",
        );
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
