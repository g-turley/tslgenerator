import '../models/category.dart';
import '../models/choice.dart';
import '../models/property.dart';
import '../models/test_frame.dart';

/// Generates test frames from parsed TSL categories and choices.
class FrameGenerator {
  /// Creates a frame generator for the given [categories].
  FrameGenerator(this.categories);

  /// The categories to generate frames from.
  final List<Category> categories;

  /// The maximum category name length, used for formatting output.
  int maxCategoryNameLength = 0;

  /// All test frames that have been generated.
  final List<TestFrame> frames = [];

  /// Generates all test frames and returns them.
  List<TestFrame> generate() {
    frames.clear();

    // Find the maximum category name length for formatting
    maxCategoryNameLength = categories.fold(
      0,
      (max, category) =>
          category.name.length > max ? category.name.length : max,
    );

    // First, pre-process normal frames to set properties
    // (this ensures if-expressions evaluate correctly for single frames)
    _preProcessNormalChoices();

    // Generate single and error frames
    _generateSingleFrames();

    // Reset all properties to false
    _resetAllProperties();

    // Generate normal frames
    _generateNormalFrames(0, {}, {});

    return frames;
  }

  /// Pre-processes normal choices to set properties correctly for single frame evaluation.
  void _preProcessNormalChoices() {
    // This is a simplified version that just sets properties from regular choices
    for (final category in categories) {
      for (final choice in category.choices) {
        if (choice.frameType == FrameType.normal && !choice.hasIfExpression) {
          for (final property in choice.properties) {
            property.value = true;
          }
        }
      }
    }
  }

  /// Resets all properties to false.
  void _resetAllProperties() {
    for (final category in categories) {
      for (final choice in category.choices) {
        for (final property in choice.properties) {
          property.value = false;
        }
        for (final property in choice.ifProperties) {
          property.value = false;
        }
        for (final property in choice.elseProperties) {
          property.value = false;
        }
      }
    }
  }

  /// Generates single and error test frames from choices marked as such.
  void _generateSingleFrames() {
    for (final category in categories) {
      for (final choice in category.choices) {
        // Regular single/error frames
        if (choice.frameType != FrameType.normal) {
          final frame = TestFrame(frames.length + 1);
          frame.setSingleFrame(category, choice, choice.frameType);
          frames.add(frame);
        }

        // If-based single/error frames
        if (choice.hasIfExpression) {
          final ifConditionResult = choice.ifExpression!.evaluate();

          if (choice.ifFrameType != FrameType.normal && ifConditionResult) {
            final frame = TestFrame(frames.length + 1);
            frame.setSingleFrame(
              category,
              choice,
              choice.ifFrameType,
              branchType: 'if',
            );
            frames.add(frame);
          }

          if (choice.hasElseClause &&
              choice.elseFrameType != FrameType.normal &&
              !ifConditionResult) {
            final frame = TestFrame(frames.length + 1);
            frame.setSingleFrame(
              category,
              choice,
              choice.elseFrameType,
              branchType: 'else',
            );
            frames.add(frame);
          }
        }
      }
    }
  }

  /// Recursively generates normal test frames by making combinations of choices.
  ///
  /// [depth] is the current category index being processed.
  /// [selectedChoices] is a map of selected choices for each category so far.
  /// [alteredProperties] is a map tracking properties that have been altered to true.
  void _generateNormalFrames(
    int depth,
    Map<Category, Choice?> selectedChoices,
    Map<String, Property> alteredProperties,
  ) {
    // Base case: we've gone through all categories, so write the frame
    if (depth >= categories.length) {
      final frame = TestFrame(frames.length + 1);

      // Build the key string
      final keyParts = <String>[];

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final choice = selectedChoices[category];

        if (choice != null) {
          final choiceIndex = category.choices.indexOf(choice) + 1;
          keyParts.add('$choiceIndex');
        } else {
          keyParts.add('0');
        }

        frame.addCategoryAndChoice(category, choice);
      }

      frame.setKey(keyParts.join('.'));
      frames.add(frame);

      // Reset altered properties
      for (final property in alteredProperties.values) {
        property.value = false;
      }

      return;
    }

    final category = categories[depth];
    bool madeSelection = false;

    // Try each choice in the current category
    for (final choice in category.choices) {
      // Skip choices that generate single/error frames
      if (choice.frameType != FrameType.normal) {
        continue;
      }

      final localAlteredProperties = <String, Property>{};

      if (choice.hasIfExpression) {
        if (choice.ifExpression!.evaluate()) {
          if (choice.ifFrameType != FrameType.normal) {
            continue; // Skip choices with single/error frames in the if branch
          }

          // Set properties for the if branch
          for (final property in choice.ifProperties) {
            if (!property.value) {
              property.value = true;
              localAlteredProperties[property.name] = property;
            }
          }
        } else if (choice.hasElseClause) {
          if (choice.elseFrameType != FrameType.normal) {
            continue; // Skip choices with single/error frames in the else branch
          }

          // Set properties for the else branch
          for (final property in choice.elseProperties) {
            if (!property.value) {
              property.value = true;
              localAlteredProperties[property.name] = property;
            }
          }
        } else {
          continue; // Skip choices where the if condition is false and there's no else
        }
      } else {
        // Set normal properties
        for (final property in choice.properties) {
          if (!property.value) {
            property.value = true;
            localAlteredProperties[property.name] = property;
          }
        }
      }

      madeSelection = true;
      selectedChoices[category] = choice;

      // Add local altered properties to the master list
      alteredProperties.addAll(localAlteredProperties);

      // Recursive call to process the next category
      _generateNormalFrames(depth + 1, selectedChoices, alteredProperties);

      // Remove local altered properties from the master list and reset them
      for (final property in localAlteredProperties.values) {
        property.value = false;
        alteredProperties.remove(property.name);
      }

      // Remove this choice from selected choices
      selectedChoices.remove(category);
    }

    // If we couldn't select any choice from this category, proceed with no selection
    if (!madeSelection) {
      selectedChoices[category] = null;
      _generateNormalFrames(depth + 1, selectedChoices, alteredProperties);
      selectedChoices.remove(category);
    }
  }

  /// Returns a string representation of all generated test frames.
  @override
  String toString() {
    final buffer = StringBuffer();

    for (final frame in frames) {
      buffer.writeln(frame.toString());
      buffer.writeln(); // Add an extra line between frames
    }

    return buffer.toString();
  }
}
