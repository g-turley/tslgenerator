# TSL Generator

A Dart port of the Template Specification Language (TSL) generator. This package provides functionality for parsing TSL files and generating output based on categories, choices, and conditional expressions.

## Features

- Parse TSL input files with categories, choices, and properties
- Support for conditional expressions with logical operators (AND, OR, NOT)
- Generate output based on the parsed input and conditions
- Debug utilities for inspecting the parsed data

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  tsl_generator: ^1.0.0
```

Then run:

```
dart pub get
```

## TSL File Format

TSL files use a specific format to define categories, choices, and properties:

```
# Category1
  Choice1:
      Property1.
      Property2.
  Choice2:
      Property3.
      Property4.

# Category2
  Choice3:
      Property5.
      Property6.
```

### Format Rules:

1. **Categories** are defined with a line starting with `#` followed by the category name
2. **Choices** are defined with 2 spaces of indentation followed by the choice name and a colon
3. **Properties** are defined with 6 spaces of indentation followed by the property name and a period

## Usage

Here's a simple example of using the TSL Generator:

```dart
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  // Create a TSL generator
  var generator = TslGenerator();
  
  // Parse an input file
  generator.parseFile('input.tsl');
  
  // Set property values (determines which conditions are true)
  var prop = generator.parseProperty('magic', false);
  prop.value = true;
  
  // Generate output
  generator.generate(0);
  
  // Clean up
  generator.cleanup();
}
```

For more detailed examples, see the `/example` folder.

## Structure

The TSL Generator uses the following key classes:

- `Property`: A named boolean value
- `Expression`: A logical expression that can be evaluated
- `Choice`: A named option with properties and conditions
- `Category`: A collection of choices
- `TslGenerator`: The main class that handles parsing and generation

## Additional information

This is a Dart port of the original C implementation. It maintains the same core functionality while adapting to Dart's object-oriented approach.

For more information about the Template Specification Language, refer to the original documentation.
