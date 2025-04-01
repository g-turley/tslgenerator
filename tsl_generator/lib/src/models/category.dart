import 'choice.dart';

/// A category in the Test Specification Language.
///
/// Categories contain choices that represent different options
/// for that category.
class Category {
  /// Creates a category with the given [name].
  Category(this.name);

  /// The name of this category.
  final String name;

  /// The choices in this category.
  final List<Choice> choices = [];

  /// Adds a choice to this category.
  void addChoice(Choice choice) {
    choices.add(choice);
  }

  /// Returns whether this category has any choices.
  bool get hasChoices => choices.isNotEmpty;

  @override
  String toString() {
    return 'Category($name: ${choices.length} choices)';
  }
}
