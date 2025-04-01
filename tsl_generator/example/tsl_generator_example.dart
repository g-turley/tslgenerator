import 'dart:io';
import 'package:tsl_generator/tsl_generator.dart';

/// Example of using the TSL Generator library programmatically.
void main() async {
  // Path to a sample TSL file
  final inputFile = File('4.spec.const.single');

  // Create the parser
  final parser = TslParser(inputFile);

  try {
    // Parse the TSL file
    final categories = parser.parse();

    // Create the generator
    final generator = FrameGenerator(categories);

    // Generate test frames
    final frames = generator.generate();

    // Print the number of frames generated
    print('Generated ${frames.length} test frames:');
    print('');

    // Print the frames
    print(generator.toString());
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
