import 'dart:io';
import 'package:args/args.dart';

import '../errors/tsl_errors.dart';
import '../generator/frame_generator.dart';
import '../models/tsl_specification.dart';

/// Command-line interface for the TSL Generator.
class TslCli {
  /// Create a CLI instance with the given arguments.
  TslCli(this.args);

  /// The command-line arguments.
  final List<String> args;

  /// Whether to output to standard output.
  bool stdOutput = false;

  /// Whether to show verbose error messages.
  bool verboseErrors = false;

  /// Whether to show colored output.
  bool useColors = true;

  /// The input file path.
  String? inputFilePath;

  /// The output file path.
  String? outputFilePath;

  /// ANSI color codes for terminal output.
  static const String _resetColor = '\x1B[0m';
  static const String _redColor = '\x1B[31m';
  static const String _greenColor = '\x1B[32m';
  static const String _yellowColor = '\x1B[33m';
  static const String _blueColor = '\x1B[34m';
  static const String _magentaColor = '\x1B[35m';
  static const String _cyanColor = '\x1B[36m';
  static const String _boldText = '\x1B[1m';

  /// Process the command-line arguments and run the generator.
  Future<void> run() async {
    // Check if colors should be disabled (e.g., in non-interactive terminals)
    _checkColorSupport();

    // Print banner
    _printBanner();

    // Set up argument parser
    final parser = _setupArgumentParser();

    // Parse arguments
    ArgResults? results;
    try {
      results = parser.parse(args);
    } catch (e) {
      _printError('Error parsing arguments: ${e.toString()}');
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
      _printVersion();
      return;
    }

    // Set options from results
    stdOutput = results['stdout'];
    verboseErrors = results['verbose'];

    if (results['output'] != null) {
      outputFilePath = results['output'];
    }

    // Get input file path
    if (results.rest.isEmpty) {
      _printError('No input file provided.');
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
      _printStatus('Parsing TSL file: $inputFilePath');
      final specification = TslSpecification.fromFile(inputFilePath!);

      _printStatus('Generating test frames...');
      final generator = FrameGenerator.fromSpecification(specification);
      final result = generator.generate();

      // Check if only the input file was provided
      if (args.length == 1) {
        // When only the input is provided, display stats and ask for confirmation to output frames.
        _printSuccess('\n${result.toSummaryString()}\n');
        stdout.write(
          'Write test frames to ${stdOutput ? 'standard output' : outputFilePath} (y/N)? ',
        );
        final answer = stdin.readLineSync()?.toLowerCase();
        if (answer == 'y' || answer == 'yes') {
          await _writeOutput(result.toFramesString());
        }
      } else {
        // When additional arguments are provided, simply output the stats.
        _printSuccess('\n${result.toSummaryString()}');
        if (outputFilePath != null) {
          await _writeOutput(result.toFramesString());
        }
      }
    } catch (e) {
      if (e is TslError) {
        _printTslError(e);
      } else {
        _printError('\nError: ${e.toString()}');
      }
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
      'stdout',
      abbr: 's',
      negatable: false,
      help: 'Output to standard output instead of a file.',
    );

    parser.addFlag(
      'verbose',
      negatable: false,
      help: 'Show verbose error messages.',
    );

    parser.addFlag(
      'no-color',
      negatable: false,
      help: 'Disable colored output.',
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
    _printHeader('Usage: tsl_generator [options] input_file\n');
    _printHeader('Options:');
    print(parser.usage);
    _printHeader('\nExamples:');
    print('  tsl_generator input.tsl -o output.tsl');
    print('  tsl_generator -s input.tsl\n');
  }

  /// Print the version information.
  void _printVersion() {
    _printHeader('TSL Generator version 1.0.0');
  }

  /// Print the banner.
  void _printBanner() {
    // Define the ASCII art using a raw string literal.
    final asciiArt = r'''
 _____  ___  __
/_  _/,' _/ / /   Test Specification Language 
 / / _\ `. / /_   Generator
/_/ /___,'/___/   
''';

    // Apply colorization (bold and cyan) to the ASCII art.
    final banner = '''
${_colorize(_boldText + _cyanColor, asciiArt)}
''';

    print(banner);
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

  /// Print a TslError with appropriate formatting.
  void _printTslError(TslError error) {
    final buffer = StringBuffer();

    // Add error type and message
    buffer.writeln(
      _colorize(
        _boldText + _redColor,
        'Error: ${error.type.name}: ${error.message}',
      ),
    );

    // Add file location information if available
    if (error.filePath != null) {
      buffer.write(_colorize(_boldText, '  at ${error.filePath}'));
      if (error.lineNumber != null) {
        buffer.write(_colorize(_boldText, ':${error.lineNumber}'));
        if (error.columnNumber != null) {
          buffer.write(_colorize(_boldText, ':${error.columnNumber}'));
        }
      }
      buffer.writeln();
    }

    // Add line content and error span if available
    if (error.lineContent != null) {
      buffer.writeln(_colorize(_blueColor, '  | ${error.lineContent}'));
      if (error.errorSpan != null) {
        buffer.writeln(_colorize(_redColor, '  | ${error.errorSpan}'));
      }
    }

    // Add suggestion if available
    if (error.suggestion != null) {
      buffer.writeln();
      buffer.writeln(_colorize(_greenColor, 'Suggestion: ${error.suggestion}'));
    }

    stderr.write(buffer.toString());
  }

  /// Print an error message.
  void _printError(String message) {
    stderr.writeln(_colorize(_redColor, message));
  }

  /// Print a success message.
  void _printSuccess(String message) {
    print(_colorize(_greenColor, message));
  }

  /// Print a status message.
  void _printStatus(String message) {
    print(_colorize(_blueColor, message));
  }

  /// Print a header.
  void _printHeader(String message) {
    print(_colorize(_boldText + _cyanColor, message));
  }

  /// Colorize a string if colors are enabled.
  String _colorize(String color, String text) {
    if (useColors) {
      return '$color$text$_resetColor';
    }
    return text;
  }

  /// Check if color support should be enabled.
  void _checkColorSupport() {
    // Disable colors if NO_COLOR env var is set or if not a terminal
    if (Platform.environment.containsKey('NO_COLOR') ||
        !stdout.hasTerminal ||
        args.contains('--no-color')) {
      useColors = false;
    }
  }
}
