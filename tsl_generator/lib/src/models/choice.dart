import 'property.dart';
import 'expression.dart';

/// The type of test frame that should be generated for a choice.
enum FrameType {
  /// A normal test frame
  normal,

  /// A "single" test frame
  single,

  /// An "error" test frame
  error;

  @override
  String toString() {
    switch (this) {
      case FrameType.normal:
        return "normal";
      case FrameType.single:
        return "single";
      case FrameType.error:
        return "error";
    }
  }
}

/// A choice within a category in the Test Specification Language.
///
/// Choices have a name and can have associated properties and expressions.
/// They can also be marked as "single" or "error" to generate specific
/// types of test frames.
class Choice {
  /// Creates a choice with the given [name].
  Choice(this.name);

  /// The name of this choice.
  final String name;

  /// The properties associated with this choice.
  final List<Property> properties = [];

  /// The properties to set if the if-expression evaluates to true.
  final List<Property> ifProperties = [];

  /// The properties to set if the if-expression evaluates to false.
  final List<Property> elseProperties = [];

  /// The "if" expression for this choice, if any.
  Expression? ifExpression;

  /// Whether this choice has an if expression.
  bool get hasIfExpression => ifExpression != null;

  /// Whether this choice has an else clause.
  bool hasElseClause = false;

  /// The type of frame to generate when not considering expressions.
  FrameType frameType = FrameType.normal;

  /// The type of frame to generate when the if-expression is true.
  FrameType ifFrameType = FrameType.normal;

  /// The type of frame to generate when the if-expression is false.
  FrameType elseFrameType = FrameType.normal;

  /// Adds a property to this choice.
  void addProperty(Property property) {
    properties.add(property);
  }

  /// Adds a property to the "if" properties list.
  void addIfProperty(Property property) {
    ifProperties.add(property);
  }

  /// Adds a property to the "else" properties list.
  void addElseProperty(Property property) {
    elseProperties.add(property);
  }

  @override
  String toString() {
    return 'Choice($name)';
  }
}
