/// A property from a Test Specification Language file.
///
/// Properties can be associated with choices and used in expressions.
class Property {
  /// Creates a property with the given [name] and [value].
  Property(this.name, {this.value = false});

  /// Name of the property.
  final String name;

  /// Current value of the property (true/false).
  bool value;

  @override
  String toString() => "Property($name: $value)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
