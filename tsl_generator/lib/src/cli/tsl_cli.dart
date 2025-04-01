import 'dart:io';

import '../generator/frame_generator.dart';
import '../parser/tsl_parser.dart';

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
    print('  TSL Generator - Dart Edition');
    print('\n  (C) 2025 - Dart Port of the Original');
    print('  TSL Generator by UC Irvine, OSU, and');
    print('  Georgia Institute of Technology, 2001-2014');
    print('----------------------------------------\n');

    // If no arguments, print usage and exit
    if (args.isEmpty) {
      _printUsage();
      return;
    }

    // Parse arguments
    if (!_parseArgs()) {
      return;
    }

    if (inputFilePath == null) {
      stderr.writeln('\nNo input file provided.\nQuitting\n');
      exit(1);
    }

    final inputFile = File(inputFilePath!);

    if (!inputFile.existsSync()) {
      stderr.writeln('\nInput file does not exist: $inputFilePath\nQuitting\n');
      exit(1);
    }

    // Set default output path if needed
    if (outputFilePath == null && !stdOutput) {
      outputFilePath = '${inputFilePath!}.tsl';
    }

    try {
      // Parse the TSL file
      final parser = TslParser(inputFile);
      final categories = parser.parse();

      // Generate test frames
      final generator = FrameGenerator(categories);
      final frames = generator.generate();

      if (countOnly) {
        // Just report the number of frames
        print('\n\t${frames.length} test frames generated\n');

        stdout.write(
          'Write test frames to ${stdOutput ? 'the standard output' : outputFilePath} (y/n)? ',
        );
        final answer = stdin.readLineSync()?.toLowerCase();

        if (answer == 'y' || answer == 'yes') {
          countOnly = false;
          await _writeOutput(generator.toString());
        }
      } else {
        await _writeOutput(generator.toString());
        print(
          '\n\t${frames.length} test frames generated and written to ${stdOutput ? 'the standard output' : outputFilePath}\n',
        );
      }
    } catch (e) {
      stderr.writeln('\nError: $e\nQuitting\n');
      exit(1);
    }
  }

  /// Parse the command-line arguments.
  bool _parseArgs() {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];

      if (arg == '--manpage') {
        _printManPage();
        return false;
      }

      if (arg.startsWith('-')) {
        // Process flags
        for (int j = 1; j < arg.length; j++) {
          final flag = arg[j];

          switch (flag) {
            case 'c':
              countOnly = true;
              break;
            case 's':
              stdOutput = true;
              break;
            case 'o':
              if (i + 1 < args.length) {
                outputFilePath = args[++i];
              } else {
                stderr.writeln(
                  '\nNo output file provided after -o flag.\nQuitting\n',
                );
                exit(1);
              }
              break;
            default:
              stderr.writeln('\nUnknown flag: -$flag\nQuitting\n');
              exit(1);
          }
        }
      } else {
        // It's the input file
        inputFilePath = arg;
      }
    }

    return true;
  }

  /// Print the usage information.
  void _printUsage() {
    print('USAGE:  tsl [ --manpage ] [ -cs ] input_file [ -o output_file ]\n');
  }

  /// Print the manual page.
  void _printManPage() {
    print('\nNAME\n\ttsl - generate test frames from a specification file\n');
    print(
      '\nSYNOPSIS\n\ttsl [ --manpage ] [ -cs ] input_file [ -o output_file ]\n',
    );
    print(
      '\nDESCRIPTION\n\tThe TSL utility generates test frames from a specification file',
    );
    print('\twritten in the extended Test Specification Language.  By default');
    print('\tit writes the test frames to a new file created by appending a');
    print(
      '\t\'.tsl\' extension to the input_file\'s name.  Options can be used',
    );
    print('\tto modify the output.\n');
    print('\nOPTIONS\n\tThe following options are supported:\n');
    print('\n\t--manpage\n\t\tPrint this man page.\n');
    print('\n\t-c\tReport the number of test frames generated, but don\'t');
    print('\t\twrite them to the output. After the number of frames is');
    print('\t\treported you will be given the option of writing them');
    print('\t\tto the output.\n');
    print('\n\t-s\tOutput is the standard output.\n');
    print(
      '\n\t-o output_file\n\t\tOutput is the file output_file unless the -s option is used.\n\n',
    );
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
