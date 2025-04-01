import '../models/category.dart';
import '../models/choice.dart';
import '../models/test_frame.dart';
import '../models/tsl_specification.dart';
import 'generator_result.dart';

/// Generates test frames from TSL categories and choices.
class FrameGenerator {
  /// Creates a frame generator from the given [specification].
  ///
  /// This is the recommended constructor when you have a complete
  /// TslSpecification.
  factory FrameGenerator.fromSpecification(TslSpecification specification) {
    return FrameGenerator(specification.categories);
  }

  /// Creates a frame generator for the given [categories].
  ///
  /// This constructor is provided for backwards compatibility.
  /// It's recommended to use [FrameGenerator.fromSpecification] instead.
  FrameGenerator(this.categories);

  /// The categories to generate frames from.
  final List<Category> categories;

  /// The maximum category name length, used for formatting output.
  int maxCategoryNameLength = 0;

  /// All test frames that have been generated.
  final List<TestFrame> frames = [];

  /// Counter for the current frame number.
  int frameCounter = 1;

  /// Generates all test frames and returns a [GeneratorResult].
  ///
  /// This method clears any previously generated frames and
  /// generates all frames defined by the TSL specification.
  GeneratorResult generate() {
    frames.clear();
    frameCounter = 1;

    // Find the maximum category name length for formatting
    maxCategoryNameLength = categories.fold(
      0,
      (max, category) =>
          category.name.length > max ? category.name.length : max,
    );

    // Generate single and error frames first
    _generateSingleFrames();

    // Then generate normal frames
    _resetAllProperties();
    _generateNormalFrames(
      List<Choice>.filled(categories.length, Choice('DUMMY')),
      0,
    );

    return GeneratorResult(List.unmodifiable(frames));
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
          final frame = TestFrame(frameCounter++);
          frame.setSingleFrame(category, choice, choice.frameType);
          frames.add(frame);
        }

        // If-based single/error frames
        if (choice.hasIfExpression) {
          _resetAllProperties();
          _preProcessProperties();

          final ifResult = choice.ifExpression!.evaluate();

          if (ifResult && choice.ifFrameType != FrameType.normal) {
            final frame = TestFrame(frameCounter++);
            frame.setSingleFrame(
              category,
              choice,
              choice.ifFrameType,
              branchType: 'if',
            );
            frames.add(frame);
          } else if (!ifResult &&
              choice.hasElseClause &&
              choice.elseFrameType != FrameType.normal) {
            final frame = TestFrame(frameCounter++);
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

  /// Pre-processes properties to their default values.
  void _preProcessProperties() {
    for (final category in categories) {
      for (final choice in category.choices) {
        if (!choice.hasIfExpression) {
          // Set properties for non-conditional choices
          for (final property in choice.properties) {
            property.value = true;
          }
        }
      }
    }
  }

  /// Recursively generates normal test frames.
  ///
  /// [choices] is an array of selected choices for each category.
  /// [catIndex] is the current category index being processed.
  void _generateNormalFrames(List<Choice> choices, int catIndex) {
    if (catIndex >= categories.length) {
      // We've selected choices for all categories, create a test frame
      _createNormalFrame(choices);
      return;
    }

    final category = categories[catIndex];
    bool selectionMade = false;

    // Try each choice in the current category
    for (final choice in category.choices) {
      // Skip choices that generate single/error frames
      if (choice.frameType != FrameType.normal) {
        continue;
      }

      // Store the state of all properties before setting new ones
      final propertyStates = <String, bool>{};
      for (final category in categories) {
        for (final c in category.choices) {
          for (final property in c.properties) {
            propertyStates[property.name] = property.value;
          }
          for (final property in c.ifProperties) {
            propertyStates[property.name] = property.value;
          }
          for (final property in c.elseProperties) {
            propertyStates[property.name] = property.value;
          }
        }
      }

      bool includeChoice = true;

      if (choice.hasIfExpression) {
        final ifResult = choice.ifExpression!.evaluate();

        if (ifResult) {
          // If branch is taken
          if (choice.ifFrameType != FrameType.normal) {
            // Skip choices with single/error frames in the if branch
            includeChoice = false;
          } else {
            // Set properties from the if branch
            for (final property in choice.ifProperties) {
              property.value = true;
            }
          }
        } else if (choice.hasElseClause) {
          // Else branch is taken
          if (choice.elseFrameType != FrameType.normal) {
            // Skip choices with single/error frames in the else branch
            includeChoice = false;
          } else {
            // Set properties from the else branch
            for (final property in choice.elseProperties) {
              property.value = true;
            }
          }
        } else {
          // No else branch and if condition is false, skip this choice
          includeChoice = false;
        }
      } else {
        // Regular choice, set properties
        for (final property in choice.properties) {
          property.value = true;
        }
      }

      if (includeChoice) {
        selectionMade = true;
        choices[catIndex] = choice;

        // Recursive call to process the next category
        _generateNormalFrames(choices, catIndex + 1);
      }

      // Restore property values
      for (final category in categories) {
        for (final c in category.choices) {
          for (final property in c.properties) {
            property.value = propertyStates[property.name] ?? false;
          }
          for (final property in c.ifProperties) {
            property.value = propertyStates[property.name] ?? false;
          }
          for (final property in c.elseProperties) {
            property.value = propertyStates[property.name] ?? false;
          }
        }
      }
    }

    // If no choice could be made, proceed with a null choice
    if (!selectionMade) {
      choices[catIndex] = Choice('EMPTY');
      _generateNormalFrames(choices, catIndex + 1);
    }
  }

  /// Creates a normal test frame from the given [choices].
  void _createNormalFrame(List<Choice> choices) {
    final frame = TestFrame(frameCounter++);

    // Build the key string
    final keyParts = <String>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final choice = choices[i];

      frame.addCategoryAndChoice(
        category,
        choice.name == 'EMPTY' ? null : choice,
      );

      // For key, we need the index of the choice within its category
      if (choice.name == 'EMPTY') {
        keyParts.add('0');
      } else {
        final choiceIndex = category.choices.indexOf(choice) + 1;
        keyParts.add('$choiceIndex');
      }
    }

    frame.setKey(keyParts.join('.'));
    frames.add(frame);
  }
}
