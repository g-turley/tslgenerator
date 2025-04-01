import 'dart:io';
import 'package:tsl_generator/tsl_generator.dart';

/// Example showing the various ways to use the TSL Generator API.
void main() async {
  print('\n=== TSL Generator Example ===\n');

  // Example 1: Parse a TSL file
  print('Example 1: Parsing a TSL file\n');
  parseFromFile();

  // Example 2: Create a TSL specification programmatically
  print('\nExample 2: Creating a TSL specification programmatically\n');
  createProgrammatically();

  // Example 3: Working with properties
  print('\nExample 3: Working with properties\n');
  workWithProperties();
}

/// Example of parsing a TSL file.
void parseFromFile() {
  try {
    // For this example, let's create a temporary TSL file
    final tempFile = File('example_spec.tsl');
    tempFile.writeAsStringSync('''
# File
  Size:
      Empty.            [property emptyfile] 
      Not empty.
  Number of occurrences:
      None.             [if !emptyfile] [property noOccurences]
      One.              [if !emptyfile]
      Many.             [if !emptyfile]
''');

    // Parse the file
    print('Parsing TSL file: ${tempFile.path}');
    final spec = TslSpecification.fromFile(tempFile.path);

    // Print info about the parsed specification
    print('Categories: ${spec.categories.length}');
    print('Properties: ${spec.properties.length}');
    print('Total choices: ${spec.totalChoicesCount}');

    // Generate frames
    final generator = FrameGenerator.fromSpecification(spec);
    final result = generator.generate();

    // Print statistics
    print('\nGeneration results:');
    print(result.toSummaryString());

    // Clean up
    tempFile.deleteSync();
  } catch (e) {
    print('Error: $e');
  }
}

/// Example of creating a TSL specification programmatically.
void createProgrammatically() {
  // Create an empty specification
  final spec = TslSpecification();

  // Create properties
  final emptyPattern = spec.createProperty('emptypattern');
  final longPattern = spec.createProperty('longpattern');

  // Create categories
  final patternCategory = Category('Pattern');
  final lengthCategory = Category('Length');

  // Create choices for pattern category
  final alphaChoice = Choice('Alpha pattern.');
  final numericChoice = Choice('Numeric pattern.');
  final mixedChoice = Choice('Mixed pattern.');
  mixedChoice.ifExpression = Expression(
    notA: true,
    propA: emptyPattern,
    propB: Property('dummy'),
  );

  // Create choices for length category
  final emptyChoice = Choice('Empty.');
  emptyChoice.addProperty(emptyPattern);

  final shortChoice = Choice('Short.');

  final longChoice = Choice('Long.');
  longChoice.addProperty(longPattern);

  // Add choices to categories
  patternCategory.addChoice(alphaChoice);
  patternCategory.addChoice(numericChoice);
  patternCategory.addChoice(mixedChoice);

  lengthCategory.addChoice(emptyChoice);
  lengthCategory.addChoice(shortChoice);
  lengthCategory.addChoice(longChoice);

  // Add categories to specification
  spec.addCategory(patternCategory);
  spec.addCategory(lengthCategory);

  // Generate frames
  final generator = FrameGenerator.fromSpecification(spec);
  final result = generator.generate();

  // Print statistics and some frames
  print('Generated ${result.totalFrames} test frames');

  if (result.frames.isNotEmpty) {
    print('\nFirst test frame:');
    print(result.frames.first.toString());
  }
}

/// Example of working with properties in a specification.
void workWithProperties() {
  // Create a specification and properties
  final spec = TslSpecification();

  // Different ways to create properties
  final prop1 = spec.createProperty('Prop1');
  spec.getOrCreateProperty('Prop2', value: true);
  spec.setPropertyValue('Prop3', true);

  // Print property values
  print('Prop1: ${prop1.value}');
  print('Prop2: ${spec.getProperty('Prop2')?.value}');
  print('Prop3: ${spec.getProperty('Prop3')?.value}');

  // Reset all properties
  print('\nResetting all properties...');
  spec.resetAllProperties();

  // Print updated values
  print('Prop1: ${prop1.value}');
  print('Prop2: ${spec.getProperty('Prop2')?.value}');
  print('Prop3: ${spec.getProperty('Prop3')?.value}');
}
