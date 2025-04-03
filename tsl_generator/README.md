# TSL Generator

A Dart implementation of the Test Specification Language (TSL) generator. This package provides functionality for defining test specifications, parsing TSL files, and generating test frames based on categories, choices, and conditional expressions.

## Features

- Create TSL specifications programmatically or parse them from files
- Define categories, choices, and properties with conditional logic
- Support for logical expressions (AND, OR, NOT) with parenthesized grouping
- Generate test frames with detailed statistics
- CLI tool with various output options

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  tsl_generator: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Usage Examples

### Creating a TSL Specification Programmatically

```dart
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  // Create a new TSL specification
  final spec = TslSpecification();
  
  // Create properties
  final emptyFile = spec.createProperty('emptyfile');
  final noOccurrences = spec.createProperty('noOccurences');
  
  // Create categories and choices
  final fileCategory = Category('File Size');
  
  final emptyChoice = Choice('Empty.');
  emptyChoice.addProperty(emptyFile);
  
  final notEmptyChoice = Choice('Not empty.');
  
  fileCategory.addChoice(emptyChoice);
  fileCategory.addChoice(notEmptyChoice);
  
  spec.addCategory(fileCategory);
  
  // Generate test frames
  final generator = FrameGenerator.fromSpecification(spec);
  final result = generator.generate();
  
  // Print statistics and frames
  print(result.toSummaryString());
  
  // Access specific frame types
  print('Total frames: ${result.totalFrames}');
  print('Single frames: ${result.singleFrames}');
  print('Error frames: ${result.errorFrames}');
}
```

### Parsing a TSL File

```dart
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  // Parse a TSL file
  final spec = TslSpecification.fromFile('input.tsl');
  
  // Get and modify properties
  final property = spec.getProperty('emptyfile');
  if (property != null) {
    property.value = true;
  }
  
  // Generate test frames
  final generator = FrameGenerator.fromSpecification(spec);
  final result = generator.generate();
  
  // Print all frames
  print(result.toString());
}
```

### Using the CLI

You can use the command-line interface directly:

```bash
dart run bin/tsl_generator.dart input.tsl -o output.tsl
```

Options:
- `-c`: Only count frames without writing them
- `-s`: Output to standard output
- `-o <file>`: Specify an output file

## TSL File Format

TSL files define categories, choices, and constraints in a hierarchical format:

```
Category1:
  Choice1.           [property PropertyName]
  Choice2.           [single]
  Choice3.           [error]
  Choice4.           [if PropertyName]

Category2:
  ChoiceA.
  ChoiceB.           [if !PropertyName] [property PropertyName2]
  ChoiceC.           [if PropertyName && PropertyName2]
```

### Format Rules:

1. **Categories** are defined with a line starting with `#` followed by the category name
2. **Choices** are defined with indentation followed by the choice name and a period
3. **Constraints** are defined in square brackets:
   - `[property Name]`: Defines a property for the choice
   - `[single]`: Marks the choice for a single test frame
   - `[error]`: Marks the choice as an error case
   - `[if Expression]`: Conditional logic for the choice

## Architecture

The TSL Generator uses the following key components:

- `TslSpecification`: The main container for all TSL elements
- `Category`: Represents a group of related choices
- `Choice`: Represents an option within a category
- `Property`: A named boolean value used in expressions
- `Expression`: A logical expression that can be evaluated
- `FrameGenerator`: Generates test frames from a specification
- `GeneratorResult`: Contains generated frames and statistics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.