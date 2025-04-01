import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('TestFrame', () {
    late Category category;
    late Choice choice;

    setUp(() {
      category = Category('TestCategory');
      choice = Choice('TestChoice.');
    });

    test('creates normal frame with category and choice', () {
      final frame = TestFrame(1);
      frame.addCategoryAndChoice(category, choice);
      frame.setKey('1.1');

      expect(frame.frameType, equals(FrameType.normal));
      expect(frame.categoriesAndChoices.length, equals(1));
      expect(frame.categoriesAndChoices[category], equals(choice));
      expect(frame.key, equals('1.1'));
    });

    test('creates single frame', () {
      final frame = TestFrame(2);
      frame.setSingleFrame(category, choice, FrameType.single);

      expect(frame.frameType, equals(FrameType.single));
      expect(frame.categoriesAndChoices.length, equals(1));
      expect(frame.categoriesAndChoices[category], equals(choice));
      expect(frame.fromIfElse, isFalse);
    });

    test('creates single frame with if/else branch', () {
      final frame = TestFrame(3);
      frame.setSingleFrame(
        category,
        choice,
        FrameType.single,
        branchType: 'if',
      );

      expect(frame.frameType, equals(FrameType.single));
      expect(frame.fromIfElse, isTrue);
      expect(frame.ifElseBranch, equals('if'));
    });

    test('creates error frame', () {
      final frame = TestFrame(4);
      frame.setSingleFrame(category, choice, FrameType.error);

      expect(frame.frameType, equals(FrameType.error));
    });

    test('handles null choice', () {
      final frame = TestFrame(5);
      frame.addCategoryAndChoice(category, null);

      expect(frame.categoriesAndChoices[category], isNull);
    });

    test('handles multiple categories and choices', () {
      final category2 = Category('SecondCategory');
      final choice2 = Choice('SecondChoice.');

      final frame = TestFrame(6);
      frame.addCategoryAndChoice(category, choice);
      frame.addCategoryAndChoice(category2, choice2);
      frame.setKey('1.1.2.1');

      expect(frame.categoriesAndChoices.length, equals(2));
      expect(frame.categoriesAndChoices[category], equals(choice));
      expect(frame.categoriesAndChoices[category2], equals(choice2));
    });

    test('toString() contains category and choice names', () {
      final frame = TestFrame(7);
      frame.addCategoryAndChoice(category, choice);
      frame.setKey('1.1');

      final string = frame.toString();

      expect(string, contains('Test Case 7'));
      expect(string, contains('TestCategory'));
      expect(string, contains('TestChoice'));
    });

    test('toString() handles empty categoriesAndChoices for normal frame', () {
      final frame = TestFrame(8);
      frame.setKey('0');

      final string = frame.toString();

      expect(string, contains('Test Case 8'));
      expect(string, contains('<No categories/choices>'));
    });

    test('toString() handles empty categoriesAndChoices for single frame', () {
      final frame = TestFrame(9);
      frame.frameType = FrameType.single;

      final string = frame.toString();

      expect(string, contains('Test Case 9'));
      expect(string, contains('<No category/choice>'));
    });
  });
}
