import 'package:tsl_generator/tsl_generator.dart' show FrameType;

import '../models/test_frame.dart';

/// Contains the results of a test frame generation operation.
///
/// This class provides access to the generated frames and various
/// statistics about them, making it easy to extract information
/// about the generation result.
class GeneratorResult {
  /// Creates a new generator result with the given [frames].
  GeneratorResult(this.frames);

  /// All generated test frames.
  final List<TestFrame> frames;

  /// Returns the total number of frames generated.
  int get totalFrames => frames.length;

  /// Returns the number of normal frames generated.
  int get normalFrames =>
      frames.where((frame) => frame.frameType == FrameType.normal).length;

  /// Returns the number of single frames generated.
  int get singleFrames =>
      frames.where((frame) => frame.frameType == FrameType.single).length;

  /// Returns the number of error frames generated.
  int get errorFrames =>
      frames.where((frame) => frame.frameType == FrameType.error).length;

  /// Returns all single frames.
  List<TestFrame> get singleFramesList =>
      frames.where((frame) => frame.frameType == FrameType.single).toList();

  /// Returns all error frames.
  List<TestFrame> get errorFramesList =>
      frames.where((frame) => frame.frameType == FrameType.error).toList();

  /// Returns a string representation of this result.
  @override
  String toString() {
    final buffer = StringBuffer();

    // Output summary statistics
    buffer.writeln('Generated $totalFrames test frames:');
    buffer.writeln('- Normal frames: $normalFrames');
    buffer.writeln('- Single frames: $singleFrames');
    buffer.writeln('- Error frames: $errorFrames');
    buffer.writeln();

    // Output all frames
    if (frames.isNotEmpty) {
      for (final frame in frames) {
        buffer.writeln(frame.toString());
        buffer.writeln(); // Add an extra line between frames
      }
    }

    return buffer.toString();
  }

  /// Returns a string containing just the frames without the summary.
  String toFramesString() {
    if (frames.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (final frame in frames) {
      buffer.writeln(frame.toString());
      buffer.writeln(); // Add an extra line between frames
    }

    return buffer.toString();
  }

  /// Returns a string containing just the summary statistics.
  String toSummaryString() {
    final buffer = StringBuffer();

    buffer.writeln('Generated $totalFrames test frames:');
    buffer.writeln('- Normal frames: $normalFrames');
    buffer.writeln('- Single frames: $singleFrames');
    buffer.writeln('- Error frames: $errorFrames');

    return buffer.toString();
  }
}
