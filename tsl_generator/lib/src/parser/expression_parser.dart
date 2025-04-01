import '../models/expression.dart';
import '../models/property.dart';
import 'tsl_parser.dart';

/// The special FALSE property used to complete expressions.
final Property _falseProperty = Property('F');

/// Parses logical expressions in TSL constraints.
class ExpressionParser {
  /// Creates an expression parser that uses the given [tslParser].
  ExpressionParser(this.tslParser);

  /// The TSL parser being used, needed to access properties.
  final TslParser tslParser;

  /// Parses an expression from the given [expressionText].
  Expression parse(String expressionText) {
    expressionText = expressionText.trim();

    // Look for OR operators outside of parentheses
    final orParts = _splitOutsideParentheses(expressionText, ' || ');
    if (orParts.length > 1) {
      final leftPart = orParts[0];
      final rightPart = orParts[1];
      return _createBinaryExpression(leftPart, rightPart, OperatorType.or);
    }

    // Look for AND operators outside of parentheses
    final andParts = _splitOutsideParentheses(expressionText, ' && ');
    if (andParts.length > 1) {
      final leftPart = andParts[0];
      final rightPart = andParts[1];
      return _createBinaryExpression(leftPart, rightPart, OperatorType.and);
    }

    // Single operand case
    return _parseOperand(expressionText);
  }

  /// Creates a binary expression with the given [leftPart], [rightPart], and [operator].
  Expression _createBinaryExpression(
    String leftPart,
    String rightPart,
    OperatorType operator,
  ) {
    final leftOperand = _parseOperand(leftPart);
    final rightOperand = _parseOperand(rightPart);

    return Expression(
      operatorType: operator,
      notA: leftOperand.notA,
      exprA: leftOperand.exprA,
      propA: leftOperand.propA,
      notB: rightOperand.notA,
      exprB: rightOperand.exprA,
      propB: rightOperand.propA,
    );
  }

  /// Parses a single operand from the given [text].
  Expression _parseOperand(String text) {
    text = text.trim();

    bool notA = false;

    // Check for negation
    if (text.startsWith('!')) {
      notA = true;
      text = text.substring(1).trim();
    }

    // Check for parenthesized expression
    if (text.startsWith('(') && text.endsWith(')')) {
      // Strip the parentheses and parse the inner expression
      final innerExpr = text.substring(1, text.length - 1).trim();
      final parsedExpr = parse(innerExpr);

      return Expression(notA: notA, exprA: parsedExpr, propB: _falseProperty);
    }

    // Check for logical operators in the operand
    if (text.contains('&&') || text.contains('||')) {
      // It's a complex expression, parse it recursively
      final parsedExpr = parse(text);

      return Expression(notA: notA, exprA: parsedExpr, propB: _falseProperty);
    }

    // Simple property
    final property = tslParser.getOrCreateProperty(text);

    return Expression(notA: notA, propA: property, propB: _falseProperty);
  }

  /// Splits the given [text] by [separator], but only if the separator is not inside parentheses.
  List<String> _splitOutsideParentheses(String text, String separator) {
    int parenLevel = 0;
    int start = 0;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == '(') {
        parenLevel++;
      } else if (text[i] == ')') {
        parenLevel--;
        if (parenLevel < 0) {
          throw TslParserException(
            'Unmatched closing parenthesis in expression: $text',
          );
        }
      } else if (parenLevel == 0 && i <= text.length - separator.length) {
        // Check if we've found the separator outside of parentheses
        if (text.substring(i, i + separator.length) == separator) {
          final leftPart = text.substring(start, i);
          final rightPart = text.substring(i + separator.length);
          return [leftPart, rightPart];
        }
      }
    }

    if (parenLevel > 0) {
      throw TslParserException(
        'Unmatched opening parenthesis in expression: $text',
      );
    }

    return [text];
  }
}
