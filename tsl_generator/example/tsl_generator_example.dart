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
  // === Create Specification ===
  final spec = TslSpecification();

  // === Define Properties ===
  final longPattern = spec.createProperty('longpattern');
  final emptyPattern = spec.createProperty('emptypattern');

  // === Define Pattern Category and Choices ===
  final patternCategory = Category('Pattern');

  final alphaChoice = Choice('Alpha pattern');
  final numericChoice = Choice('Numeric pattern');

  final mixedChoice = Choice('Mixed pattern');
  mixedChoice.ifExpression = Expression(
    notA: true,
    propA: emptyPattern,
    propB: longPattern,
  ); // [if !emptypattern || longpattern]

  patternCategory
    ..addChoice(alphaChoice)
    ..addChoice(numericChoice)
    ..addChoice(mixedChoice);

  // === Define Length Category and Choices ===
  final lengthCategory = Category('Length');

  final emptyChoice = Choice('Empty')..addProperty(emptyPattern); // [property emptypattern]
  final shortChoice = Choice('Short');
  final longChoice = Choice('Long')..addProperty(longPattern);   // [property longpattern]

  lengthCategory
    ..addChoice(emptyChoice)
    ..addChoice(shortChoice)
    ..addChoice(longChoice);

  // === Add Categories to Specification ===
  spec
    ..addCategory(lengthCategory)
    ..addCategory(patternCategory);

  // === Generate TSL and Frames ===
  print(spec.toTslString());

  /*
  TSL Output:

  Length:
    Empty. [property emptypattern]
    Short.
    Long. [property longpattern]

  Pattern:
    Alpha pattern.
    Numeric pattern.
    Mixed pattern. [if !emptypattern || longpattern]
  */

  final generator = FrameGenerator.fromSpecification(spec);
  final result = generator.generate();

  // === Output Results ===
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
