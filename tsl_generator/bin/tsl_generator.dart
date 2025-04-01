import 'dart:io';
import 'package:tsl_generator/tsl_generator.dart';

/// Main entry point for the TSL Generator CLI tool.
void main(List<String> args) async {
  final cli = TslCli(args);
  await cli.run();
  exit(0);
}
