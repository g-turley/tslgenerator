import 'property.dart';

/// The operator type used in an expression.
enum OperatorType {
  /// Logical OR operator (||)
  or,

  /// Logical AND operator (&&)
  and;

  @override
  String toString() {
    switch (this) {
      case OperatorType.or:
        return "||";
      case OperatorType.and:
        return "&&";
    }
  }
}

/// A logical expression in the Test Specification Language.
///
/// Expressions contain operands that can be either properties or
/// other expressions. They also have a logical operator (AND or OR)
/// and each operand can be negated.
class Expression {
  /// Creates an expression with the specified properties.
  Expression({
    this.operatorType = OperatorType.or,
    this.notA = false,
    this.notB = false,
    this.exprA,
    this.exprB,
    this.propA,
    this.propB,
  });

  /// The operator type (AND or OR) of this expression.
  final OperatorType operatorType;

  /// Whether the first operand is negated.
  final bool notA;

  /// Whether the second operand is negated.
  final bool notB;

  /// The first operand as an expression (if this is an expression operand).
  final Expression? exprA;

  /// The second operand as an expression (if this is an expression operand).
  final Expression? exprB;

  /// The first operand as a property (if this is a property operand).
  final Property? propA;

  /// The second operand as a property (if this is a property operand).
  final Property? propB;

  /// Whether the first operand is an expression.
  bool get isExprA => exprA != null;

  /// Whether the second operand is an expression.
  bool get isExprB => exprB != null;

  /// Evaluates the expression based on the current values of properties.
  bool evaluate() {
    bool a;
    if (isExprA) {
      a = exprA!.evaluate();
    } else {
      a = propA!.value;
    }

    if (notA) {
      a = !a;
    }

    // Handle single operand case
    if (propB == null && exprB == null) {
      return a;
    }

    bool b;
    if (isExprB) {
      b = exprB!.evaluate();
    } else {
      b = propB!.value;
    }

    if (notB) {
      b = !b;
    }

    return operatorType == OperatorType.and ? a && b : a || b;
  }

  @override
  String toString() {
    String left;
    if (isExprA) {
      if (notA) {
        left = '(!(${exprA!}))';
      } else {
        left = '(${exprA!})';
      }
    } else {
      left = '${notA ? '!' : ''}${propA!.name}';
    }

    if (propB == null && exprB == null) {
      return left;
    }

    String right;
    if (isExprB) {
      if (notB) {
        right = '(!(${exprB!}))';
      } else {
        right = '(${exprB!})';
      }
    } else {
      right = '${notB ? '!' : ''}${propB!.name}';
    }

    return '$left ${operatorType.toString()} $right';
  }
}
