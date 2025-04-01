import '../errors/tsl_errors.dart';
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
  ///
  /// Optional [lineNumber] and [columnOffset] for error reporting.
  Expression parse(
    String expressionText, {
    int? lineNumber,
    int? columnOffset,
  }) {
    expressionText = expressionText.trim();
    if (expressionText.isEmpty) {
      throw TslError(
        message: 'Empty expression',
        type: TslErrorType.expression,
        filePath: tslParser.inputFile.path,
        lineNumber: lineNumber,
        columnNumber: columnOffset,
        suggestion: 'Provide a valid logical expression',
      );
    }

    try {
      // Look for OR operators outside of parentheses
      final orParts = _splitOutsideParentheses(expressionText, ' || ');
      if (orParts.length > 1) {
        final leftPart = orParts[0];
        final rightPart = orParts[1];

        // Calculate column offsets for recursive parsing
        final orOperatorPos = leftPart.length + (columnOffset ?? 0);

        return _createBinaryExpression(
          leftPart,
          rightPart,
          OperatorType.or,
          lineNumber: lineNumber,
          leftColumnOffset: columnOffset,
          rightColumnOffset: orOperatorPos + 4, // length of ' || '
        );
      }

      // Look for AND operators outside of parentheses
      final andParts = _splitOutsideParentheses(expressionText, ' && ');
      if (andParts.length > 1) {
        final leftPart = andParts[0];
        final rightPart = andParts[1];

        // Calculate column offsets for recursive parsing
        final andOperatorPos = leftPart.length + (columnOffset ?? 0);

        return _createBinaryExpression(
          leftPart,
          rightPart,
          OperatorType.and,
          lineNumber: lineNumber,
          leftColumnOffset: columnOffset,
          rightColumnOffset: andOperatorPos + 4, // length of ' && '
        );
      }

      // Single operand case
      return _parseOperand(
        expressionText,
        lineNumber: lineNumber,
        columnOffset: columnOffset,
      );
    } catch (e) {
      if (e is TslError) {
        rethrow;
      }
      throw TslError(
        message: 'Error parsing expression: ${e.toString()}',
        type: TslErrorType.expression,
        filePath: tslParser.inputFile.path,
        lineNumber: lineNumber,
        columnNumber: columnOffset,
        suggestion: 'Check the syntax of your expression',
      );
    }
  }

  /// Creates a binary expression with the given [leftPart], [rightPart], and [operator].
  Expression _createBinaryExpression(
    String leftPart,
    String rightPart,
    OperatorType operator, {
    int? lineNumber,
    int? leftColumnOffset,
    int? rightColumnOffset,
  }) {
    try {
      final leftOperand = _parseOperand(
        leftPart,
        lineNumber: lineNumber,
        columnOffset: leftColumnOffset,
      );
      final rightOperand = _parseOperand(
        rightPart,
        lineNumber: lineNumber,
        columnOffset: rightColumnOffset,
      );

      return Expression(
        operatorType: operator,
        notA: leftOperand.notA,
        exprA: leftOperand.exprA,
        propA: leftOperand.propA,
        notB: rightOperand.notA,
        exprB: rightOperand.exprA,
        propB: rightOperand.propA,
      );
    } catch (e) {
      if (e is TslError) {
        rethrow;
      }
      throw TslError(
        message: 'Error creating binary expression: ${e.toString()}',
        type: TslErrorType.expression,
        filePath: tslParser.inputFile.path,
        lineNumber: lineNumber,
        suggestion:
            'Check both sides of your ${operator.toString()} expression',
      );
    }
  }

  /// Parses a single operand from the given [text].
  Expression _parseOperand(String text, {int? lineNumber, int? columnOffset}) {
    text = text.trim();
    if (text.isEmpty) {
      throw TslError(
        message: 'Empty operand',
        type: TslErrorType.expression,
        filePath: tslParser.inputFile.path,
        lineNumber: lineNumber,
        columnNumber: columnOffset,
        suggestion: 'Provide a valid property name or expression',
      );
    }

    bool notA = false;
    int textColumnOffset = columnOffset ?? 0;
    String? exclamationTrimmedText;

    // Check for negation
    if (text.startsWith('!')) {
      notA = true;
      exclamationTrimmedText = text.substring(1).trim();
      textColumnOffset += 1; // Move past the ! character

      if (exclamationTrimmedText.isEmpty) {
        throw TslError(
          message: 'Missing operand after negation (!)',
          type: TslErrorType.expression,
          filePath: tslParser.inputFile.path,
          lineNumber: lineNumber,
          columnNumber: textColumnOffset,
          suggestion:
              'Provide a property or expression to negate, e.g., !PropertyName',
        );
      }
    }

    // Check for parenthesized expression
    if ((text.startsWith('(') || (exclamationTrimmedText?.startsWith('(') ?? false)) && text.endsWith(')')) {
      // We had a leading negation, so now can commit to it.
      if (exclamationTrimmedText != null) {
        text = exclamationTrimmedText;
      }
      // Strip the parentheses and parse the inner expression
      final innerExpr = text.substring(1, text.length - 1).trim();
      if (innerExpr.isEmpty) {
        throw TslError(
          message: 'Empty parentheses',
          type: TslErrorType.expression,
          filePath: tslParser.inputFile.path,
          lineNumber: lineNumber,
          columnNumber: textColumnOffset,
          suggestion:
              'Remove empty parentheses or add an expression inside them',
        );
      }

      final parsedExpr = parse(
        innerExpr,
        lineNumber: lineNumber,
        columnOffset: textColumnOffset + 1,
      );

      return Expression(notA: notA, exprA: parsedExpr, propB: _falseProperty);
    }

    // Check for logical operators in the operand
    if (text.contains('&&') || text.contains('||')) {
      // It's a complex expression, parse it recursively
      final parsedExpr = parse(
        text,
        lineNumber: lineNumber,
        columnOffset: textColumnOffset,
      );

      return Expression(notA: false, exprA: parsedExpr, propB: _falseProperty);
    }

    // Simple property - must already be defined
    try {
      final property = tslParser.getProperty(
        exclamationTrimmedText ?? text,
        lineNumber: lineNumber,
        columnNumber: textColumnOffset,
      );

      return Expression(notA: exclamationTrimmedText != null, propA: property, propB: _falseProperty);
    } catch (e) {
      if (e is TslError) {
        // Add extra suggestions for the property error
        throw TslError(
          message: e.message,
          type: e.type,
          filePath: e.filePath,
          lineNumber: e.lineNumber,
          columnNumber: e.columnNumber,
          lineContent: e.lineContent,
          errorSpan: e.errorSpan,
          suggestion:
              e.suggestion ??
              'Define the property "$text" using [property $text] before using it in an expression',
        );
      }
      rethrow;
    }
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
          throw TslError(
            message: 'Unmatched closing parenthesis in expression: $text',
            type: TslErrorType.expression,
            filePath: tslParser.inputFile.path,
            suggestion:
                'Add a matching opening parenthesis or remove the extra closing parenthesis',
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
      throw TslError(
        message: 'Unmatched opening parenthesis in expression: $text',
        type: TslErrorType.expression,
        filePath: tslParser.inputFile.path,
        suggestion:
            'Add a matching closing parenthesis or remove the extra opening parenthesis',
      );
    }

    return [text];
  }
}
