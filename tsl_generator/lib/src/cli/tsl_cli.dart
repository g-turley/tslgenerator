import 'dart:io';
import 'package:args/args.dart';

import '../generator/frame_generator.dart';
import '../models/tsl_specification.dart';

/// Command-line interface for the TSL Generator.
class TslCli {
  /// Create a CLI instance with the given arguments.
  TslCli(this.args);

  /// The command-line arguments.
  final List<String> args;

  /// Whether to only count frames, not write them.
  bool countOnly = false;

  /// Whether to output to standard output.
  bool stdOutput = false;

  /// The input file path.
  String? inputFilePath;

  /// The output file path.
  String? outputFilePath;

  /// Process the command-line arguments and run the generator.
  Future<void> run() async {
    // Print banner
    print('\n----------------------------------------');
    print('  TSL Generator');
    print('  Test Specification Language Generator');
    print('----------------------------------------\n');

    // Set up argument parser
    final parser = _setupArgumentParser();

    // Parse arguments
    ArgResults? results;
    try {
      results = parser.parse(args);
    } catch (e) {
      stderr.writeln('\nError: $e');
      _printUsage(parser);
      exit(1);
    }

    // Handle help
    if (results['help']) {
      _printUsage(parser);
      return;
    }

    // Handle version
    if (results['version']) {
      print('TSL Generator version 1.0.0');
      return;
    }

    // Set options from results
    countOnly = results['count-only'];
    stdOutput = results['stdout'];

    if (results['output'] != null) {
      outputFilePath = results['output'];
    }

    // Get input file path
    if (results.rest.isEmpty) {
      stderr.writeln('\nNo input file provided.');
      _printUsage(parser);
      exit(1);
    }

    inputFilePath = results.rest[0];

    // Set default output path if needed
    if (outputFilePath == null && !stdOutput) {
      outputFilePath = '${inputFilePath!}.tsl';
    }

    try {
      // Parse the TSL file and generate frames
      final specification = TslSpecification.fromFile(inputFilePath!);
      final generator = FrameGenerator.fromSpecification(specification);
      final result = generator.generate();

      if (countOnly) {
        // Just report the number of frames
        print('\n${result.toSummaryString()}\n');

        stdout.write(
          'Write test frames to ${stdOutput ? 'standard output' : outputFilePath} (y/n)? ',
        );
        final answer = stdin.readLineSync()?.toLowerCase();

        if (answer == 'y' || answer == 'yes') {
          countOnly = false;
          await _writeOutput(result.toFramesString());
        }
      } else {
        await _writeOutput(result.toFramesString());
        print('\n${result.toSummaryString()}');
        print(
          '\nTest frames written to ${stdOutput ? 'standard output' : outputFilePath}\n',
        );
      }
    } catch (e) {
      stderr.writeln('\nError: $e');
      exit(1);
    }
  }

  /// Set up the argument parser with all available options.
  ArgParser _setupArgumentParser() {
    final parser = ArgParser();

    parser.addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display this help information.',
    );

    parser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Display version information.',
    );

    parser.addFlag(
      'count-only',
      abbr: 'c',
      negatable: false,
      help: 'Only report the number of frames generated.',
    );

    parser.addFlag(
      'stdout',
      abbr: 's',
      negatable: false,
      help: 'Output to standard output instead of a file.',
    );

    parser.addOption(
      'output',
      abbr: 'o',
      help: 'Specify the output file path.',
      valueHelp: 'FILE',
    );

    return parser;
  }

  /// Print the usage information.
  void _printUsage(ArgParser parser) {
    print('Usage: tsl [options] input_file\n');
    print('Options:');
    print(parser.usage);
    print('\nExample:');
    print('  tsl input.tsl -o output.tsl');
    print('  tsl -c input.tsl');
    print('  tsl -s input.tsl\n');
  }

  /// Write the output to the specified destination.
  Future<void> _writeOutput(String output) async {
    if (stdOutput) {
      stdout.write(output);
    } else {
      final file = File(outputFilePath!);
      await file.writeAsString(output);
    }
  }
}
