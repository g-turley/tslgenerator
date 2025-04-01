import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('GeneratorResult', () {
    late List<TestFrame> testFrames;
    late Category testCategory;
    late Choice testChoice;

    setUp(() {
      // Create a category and choice for the test frames
      testCategory = Category('TestCategory');
      testChoice = Choice('TestChoice.');

      // Create a mix of normal, single, and error frames
      testFrames = [];

      // Add 3 normal frames
      for (int i = 1; i <= 3; i++) {
        final frame = TestFrame(i);
        frame.frameType = FrameType.normal;
        frame.addCategoryAndChoice(testCategory, testChoice);
        frame.setKey('1.1');
        testFrames.add(frame);
      }

      // Add 2 single frames
      for (int i = 4; i <= 5; i++) {
        final frame = TestFrame(i);
        frame.setSingleFrame(testCategory, testChoice, FrameType.single);
        testFrames.add(frame);
      }

      // Add 1 error frame
      final errorFrame = TestFrame(6);
      errorFrame.setSingleFrame(testCategory, testChoice, FrameType.error);
      testFrames.add(errorFrame);
    });

    test('counts frames correctly', () {
      final result = GeneratorResult(testFrames);

      expect(result.totalFrames, equals(6));
      expect(result.normalFrames, equals(3));
      expect(result.singleFrames, equals(2));
      expect(result.errorFrames, equals(1));
    });

    test('filters frames by type', () {
      final result = GeneratorResult(testFrames);

      expect(result.singleFramesList.length, equals(2));
      expect(result.errorFramesList.length, equals(1));

      // Verify the correct frames are returned
      for (final frame in result.singleFramesList) {
        expect(frame.frameType, equals(FrameType.single));
      }

      for (final frame in result.errorFramesList) {
        expect(frame.frameType, equals(FrameType.error));
      }
    });

    test('generates summary string', () {
      final result = GeneratorResult(testFrames);
      final summary = result.toSummaryString();

      expect(summary, contains('Generated 6 test frames'));
      expect(summary, contains('- Normal frames: 3'));
      expect(summary, contains('- Single frames: 2'));
      expect(summary, contains('- Error frames: 1'));
    });

    test('generates frames string', () {
      final result = GeneratorResult(testFrames);
      final framesString = result.toFramesString();

      // Ensure all frames are included
      for (int i = 1; i <= 6; i++) {
        expect(framesString, contains('Test Case $i'));
      }

      // Ensure category and choice are included
      expect(framesString, contains('TestCategory'));
      expect(framesString, contains('TestChoice'));
    });

    test('generates full string with toString()', () {
      final result = GeneratorResult(testFrames);
      final fullString = result.toString();

      // Should contain both summary and frames
      expect(fullString, contains('Generated 6 test frames'));
      for (int i = 1; i <= 6; i++) {
        expect(fullString, contains('Test Case $i'));
      }
    });

    test('handles empty frames list', () {
      final result = GeneratorResult([]);

      expect(result.totalFrames, equals(0));
      expect(result.normalFrames, equals(0));
      expect(result.singleFrames, equals(0));
      expect(result.errorFrames, equals(0));
      expect(result.singleFramesList, isEmpty);
      expect(result.errorFramesList, isEmpty);

      // Should still generate valid strings
      expect(result.toSummaryString(), contains('Generated 0 test frames'));
      expect(result.toFramesString(), equals(''));
    });
  });
}
