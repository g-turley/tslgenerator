// test/generator/if_else_error_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {

    test('All Examples from Documentation', () {
      final file = File('test/all_examples.tsl');
      try {
        file.writeAsStringSync('''
# Properties Setup
  Init:
    PropA. [property A]
    PropB. [property B]
    PropC. [property C]
    PropD. [property D]
    PropNonEmpty. [property NonEmpty]
    PropHmmmmm. [property Hmmmmm]
    PropRadical. [property Radical]
    PropCool. [property Cool]
    PropNoWay. [property NoWay]
    PropIC. [property IC]
    PropRandom. [property Random]
    PropOh. [property Oh]
    PropYeah. [property Yeah]
    PropLong. [property Long]
    PropUnquoted. [property Unquoted]
    PropZero. [property Zero]
    PropRandQuoted. [property RandQuoted]

# Example 1
  Example1:
    If A. [if A]
    Normal.

# Example 2
  Example2:
    If Not B. [if !B]
    Normal.

# Example 3
  Example3:
    If A or B. [if A || B]
    Normal.

# Example 4
  Example4:
    If A and B. [if A && B]
    Normal.

# Example 5
  Example5:
    If Not A and B. [if !(A && B)]
    Normal.

# Example 6
  Example6:
    If A and B or C. [if A && B || C]
    Normal.

# Example 7
  Example7:
    If A and B_or_C and D. [if A && (B || C) && D]
    Normal.

# Example 8
  Example8:
    If A or Not B and Not C. [if A || !B && !C]
    Normal.

# Example 9
  Example9:
    Complex. [if !(!A || B) && C || D]
    Normal.

# Error Examples
  ErrorExample1:
    Simple If Error. [if NonEmpty][error]
    Normal.

  ErrorExample2:
    If Error Else. [if Hmmmmm][single][else]
    Normal.

  ErrorExample3:
    If Else Error. [if Radical][property Cool][else][error]
    Normal.

  ErrorExample4:
    If Single Else. [if NoWay][single][else]
    Normal.

  ErrorExample5:
    Just Error. [error]
    Normal.

  ErrorExample6:
    Property Single. [property IC][single]
    Normal.

  ErrorExample7:
    Single If. [single][if Random][property RandQuoted]
    Normal.

  ErrorExample8:
    Property List. [property Oh, Yeah]
    Normal.

  ErrorExample9:
    Property If Error. [property Long][if Unquoted][error][else][property Zero]
    Normal.
''');

        final parser = TslParser(file);
        final categories = parser.parse();
        final generator = FrameGenerator(categories);
        final result = generator.generate();

        // Just verify that frames are generated without exceptions
        expect(result.totalFrames, greaterThan(0));

        // Check that error and single frames exist
        expect(result.errorFrames, greaterThan(0));
        expect(result.singleFrames, greaterThan(0));
      } finally {
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    });
}
