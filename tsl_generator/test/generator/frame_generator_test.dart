import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('FrameGenerator', () {
    test('generates single frames', () {
      // Create categories and choices
      final category = Category('TestCategory');

      final choice1 = Choice('Choice1.');
      final choice2 = Choice('Choice2.');
      choice2.frameType = FrameType.single;

      final choice3 = Choice('Choice3.');
      choice3.frameType = FrameType.error;

      category.addChoice(choice1);
      category.addChoice(choice2);
      category.addChoice(choice3);

      // Generate frames
      final generator = FrameGenerator([category]);
      final frames = generator.generate();

      // Should generate 2 single/error frames plus normal frames
      expect(frames.length, equals(3));

      // First two frames should be single/error frames
      expect(frames[0].frameType, equals(FrameType.single));
      expect(frames[1].frameType, equals(FrameType.error));
    });

    test('generates conditional frames', () {
      // Create categories and choices with conditions
      final category1 = Category('Category1');
      final category2 = Category('Category2');

      final propA = Property('A', value: true); // Set to true directly

      final choice1 = Choice('Choice1.');
      choice1.addProperty(propA);

      final choice2 = Choice('Choice2.');
      choice2.ifExpression = Expression(
        propA: propA,
        propB: Property('Dummy'), // Dummy property for convenience
      );

      final choice3 = Choice('Choice3.');

      category1.addChoice(choice1);
      category2.addChoice(choice2);
      category2.addChoice(choice3);

      // Generate frames
      final generator = FrameGenerator([category1, category2]);
      final frames = generator.generate();

      // Should generate frames for valid combinations
      // Category1.Choice1 + Category2.Choice2
      // Category1.Choice1 + Category2.Choice3
      expect(frames.length, equals(2));

      // Check keys
      expect(frames[0].key, equals('1.1'));
      expect(frames[1].key, equals('1.2'));
    });

    test('handles complex conditions correctly', () {
      // Create categories and choices with complex conditions
      final category1 = Category('Category1');
      final category2 = Category('Category2');

      final propA = Property('A');
      final propB = Property('B');

      final choice1 = Choice('Choice1.');
      choice1.addProperty(propA);

      final choice2 = Choice('Choice2.');
      choice2.ifExpression = Expression(
        operatorType: OperatorType.and,
        propA: propA,
        propB: propB,
      );

      final choice3 = Choice('Choice3.');
      choice3.addProperty(propB);

      category1.addChoice(choice1);
      category1.addChoice(choice3);
      category2.addChoice(choice2);

      // Generate frames
      final generator = FrameGenerator([category1, category2]);
      final frames = generator.generate();

      // Should generate frames for valid combinations:
      // Category1.Choice1 + Category2.Choice2 (when propA and propB are true)
      // Category1.Choice3 + Category2.<none> (when propB is true but propA is false)
      expect(frames.length, equals(2));
    });

    test('handles if-else constraints correctly', () {
      // Create categories and choices with if-else constraints
      final category = Category('Category');

      final propA = Property('A');

      final choice1 = Choice('Choice1.');
      choice1.addProperty(propA);

      final choice2 = Choice('Choice2.');
      choice2.ifExpression = Expression(propA: propA, propB: Property('Dummy'));
      choice2.hasElseClause = true;
      choice2.frameType = FrameType.normal;
      choice2.ifFrameType = FrameType.single;

      category.addChoice(choice1);
      category.addChoice(choice2);

      // Generate frames
      final generator = FrameGenerator([category]);
      final frames = generator.generate();

      // Find the frame that should be a single frame
      final singleFrame = frames.firstWhere(
        (frame) => frame.fromIfElse && frame.ifElseBranch == 'if',
        orElse:
            () => TestFrame(
              0,
            ), // Dummy frame that will fail the test if not found
      );

      expect(singleFrame.frameType, equals(FrameType.single));
      expect(singleFrame.fromIfElse, isTrue);
      expect(singleFrame.ifElseBranch, equals('if'));
    });

    test('generates correct number of frames', () {
      // Create a more complex test case with multiple categories
      final category1 = Category('Category1');
      final category2 = Category('Category2');
      final category3 = Category('Category3');

      for (int i = 1; i <= 3; i++) {
        category1.addChoice(Choice('C1_$i.'));
      }

      for (int i = 1; i <= 2; i++) {
        category2.addChoice(Choice('C2_$i.'));
      }

      for (int i = 1; i <= 2; i++) {
        category3.addChoice(Choice('C3_$i.'));
      }

      // Generate frames
      final generator = FrameGenerator([category1, category2, category3]);
      final frames = generator.generate();

      // Should generate 3 * 2 * 2 = 12 frames
      expect(frames.length, equals(12));

      // Check some of the keys
      expect(frames[0].key, equals('1.1.1'));
      expect(frames[1].key, equals('1.1.2'));
      expect(frames[2].key, equals('1.2.1'));
    });
  });
}
