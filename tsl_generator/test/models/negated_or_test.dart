// test/models/negated_or_test.dart
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('Negated OR Expression', () {
    test('evaluates !(A || B) correctly', () {
      // Create properties
      final propA = Property('A');
      final propB = Property('B');

      // Create the negated OR expression: !(A || B)
      final innerExpr = Expression(
        operatorType: OperatorType.or,
        propA: propA,
        propB: propB,
      );

      final negatedOrExpr = Expression(
        notA: true,
        exprA: innerExpr,
        propB: Property('Dummy'), // Just for structure
      );

      // Test all combinations:

      // Case 1: !(false || false) = true
      propA.value = false;
      propB.value = false;
      expect(negatedOrExpr.evaluate(), isTrue);

      // Case 2: !(true || false) = false
      propA.value = true;
      propB.value = false;
      expect(negatedOrExpr.evaluate(), isFalse);

      // Case 3: !(false || true) = false
      propA.value = false;
      propB.value = true;
      expect(negatedOrExpr.evaluate(), isFalse);

      // Case 4: !(true || true) = false
      propA.value = true;
      propB.value = true;
      expect(negatedOrExpr.evaluate(), isFalse);
    });

    test('evaluates complex case from real-world example', () {
      // Create the properties
      final excludeLinesOption = Property('excludeLinesOption');
      final keepLinesOption = Property('keepLinesOption');

      // Create !(excludeLinesOption || keepLinesOption)
      final innerExpr = Expression(
        operatorType: OperatorType.or,
        propA: excludeLinesOption,
        propB: keepLinesOption,
      );

      final complexExpr = Expression(
        notA: true,
        exprA: innerExpr,
        propB: Property('Dummy'), // Just for structure
      );

      // When both are false, the result should be true
      excludeLinesOption.value = false;
      keepLinesOption.value = false;
      expect(complexExpr.evaluate(), isTrue);

      // When either is true, the result should be false
      excludeLinesOption.value = true;
      keepLinesOption.value = false;
      expect(complexExpr.evaluate(), isFalse);

      excludeLinesOption.value = false;
      keepLinesOption.value = true;
      expect(complexExpr.evaluate(), isFalse);

      excludeLinesOption.value = true;
      keepLinesOption.value = true;
      expect(complexExpr.evaluate(), isFalse);
    });

    test('expression string representation is correct', () {
      // Create properties
      final propA = Property('A');
      final propB = Property('B');

      // Create the negated OR expression: !(A || B)
      final innerExpr = Expression(
        operatorType: OperatorType.or,
        propA: propA,
        propB: propB,
      );

      final negatedOrExpr = Expression(
        notA: true,
        exprA: innerExpr,
      );

      // Test string representation
      expect(
        negatedOrExpr.toString().replaceAll(' ', ''),
        contains('(!(A||B))'), // Ignore whitespace
      );
    });
  });
}
