import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  group('Expression', () {
    late Property propA;
    late Property propB;

    setUp(() {
      propA = Property('A');
      propB = Property('B');
    });

    test('can evaluate a simple property expression', () {
      final expr = Expression(propA: propA, propB: propB);

      // Both properties are false by default
      expect(expr.evaluate(), equals(false));

      // Set first property to true
      propA.value = true;
      expect(expr.evaluate(), equals(true));

      // Set both properties to true
      propB.value = true;
      expect(expr.evaluate(), equals(true));

      // Set first property to false, second to true
      propA.value = false;
      expect(expr.evaluate(), equals(true));
    });

    test('can evaluate expressions with operators', () {
      // AND expression
      final andExpr = Expression(
        operatorType: OperatorType.and,
        propA: propA,
        propB: propB,
      );

      // Both false initially
      expect(andExpr.evaluate(), equals(false));

      // Only first true
      propA.value = true;
      expect(andExpr.evaluate(), equals(false));

      // Both true
      propB.value = true;
      expect(andExpr.evaluate(), equals(true));

      // Only second true
      propA.value = false;
      expect(andExpr.evaluate(), equals(false));
    });

    test('can evaluate expressions with negation', () {
      // NOT expressions
      final notExpr = Expression(notA: true, propA: propA, propB: propB);

      // Both false initially (but A is negated)
      expect(notExpr.evaluate(), equals(true));

      // A is true, but negated to false
      propA.value = true;
      expect(notExpr.evaluate(), equals(false));
    });

    test('can evaluate nested expressions', () {
      final propC = Property('C');

      // (A && B) || !C
      final nestedExpr = Expression(
        operatorType: OperatorType.or,
        exprA: Expression(
          operatorType: OperatorType.and,
          propA: propA,
          propB: propB,
        ),
        propB: propC,
        notB: true,
      );

      // A and B are false, C is false (negated to true)
      expect(nestedExpr.evaluate(), equals(true));

      // Set C to true (negated to false)
      propC.value = true;
      expect(nestedExpr.evaluate(), equals(false));

      // Set A and B to true
      propA.value = true;
      propB.value = true;
      expect(nestedExpr.evaluate(), equals(true));
    });

    test('has correct string representation', () {
      final expr = Expression(
        operatorType: OperatorType.and,
        propA: propA,
        propB: propB,
      );

      expect(expr.toString(), equals('A && B'));

      final nestedExpr = Expression(
        operatorType: OperatorType.or,
        notA: true,
        exprA: Expression(
          operatorType: OperatorType.and,
          propA: propA,
          propB: propB,
        ),
        propB: Property('C'),
      );

      expect(nestedExpr.toString(), equals('(!(A && B)) || C'));
    });
  });
}
