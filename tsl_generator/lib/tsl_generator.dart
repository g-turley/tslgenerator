/// A library for generating test frames from Test Specification Language (TSL) files.
///
/// The TSL Generator parses specifications written in the Test Specification Language
/// and generates test frames based on those specifications. This library provides
/// both a high-level API for working with TSL specifications and test frames,
/// as well as lower-level components for more fine-grained control.
///
/// # Quick Start
///
/// ```dart
/// // Parse a TSL file
/// final spec = TslSpecification.fromFile('input.tsl');
///
/// // Generate test frames
/// final generator = FrameGenerator.fromSpecification(spec);
/// final result = generator.generate();
///
/// // Print statistics
/// print(result.toSummaryString());
/// ```
library;

// Core models
export 'src/models/category.dart';
export 'src/models/choice.dart';
export 'src/models/expression.dart';
export 'src/models/property.dart';
export 'src/models/test_frame.dart';
export 'src/models/tsl_specification.dart';

// Parser components
export 'src/parser/tsl_parser.dart';
export 'src/parser/expression_parser.dart';

// Generator components
export 'src/generator/frame_generator.dart';
export 'src/generator/generator_result.dart';

// CLI components
export 'src/cli/tsl_cli.dart';

// Constants
export 'src/constants.dart';
