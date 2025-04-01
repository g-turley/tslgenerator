import 'dart:io';
import 'package:test/test.dart';
import 'package:tsl_generator/tsl_generator.dart';

void main() {
  late File simpleTslFile1;
  late File complexTslFile1;
  late File complexTslFile2;
  late File complexTslFile3;
  late File complexTslFile4;

  setUp(() {
    simpleTslFile1 = File('test/1_simple_sample.tsl');
    simpleTslFile1.writeAsStringSync('''
# File
  Size:
      Empty.			[property emptyfile] 
      Not empty.
  Number of occurrences of the pattern in the file:
      None.			[if !emptyfile] [property noOccurences]
      One.				[if !emptyfile]
      Many.				[if !emptyfile]
  Number of occurrences of the pattern in one line:
      One.				[if !noOccurences && !emptyfile]
      Many.			[if !noOccurences && !emptyfile]
  Position of the pattern in the file:
      First line.		[if !emptyfile]
      Last line.		[if !emptyfile]
      Any.				[if !emptyfile]
''');
    complexTslFile1 = File('test/1_complex_sample.tsl');
    complexTslFile1.writeAsStringSync('''
# File
  Size:
      Empty.			
      Not empty.
  Number of occurrences of the pattern in the file:
      None.			
      One.				
      Many.				
  Number of occurrences of the pattern in one line:
      One.				
      Many.			
  Position of the pattern in the file:
      First line.		
      Last line.		
      Any.				

# Pattern
  Length of the pattern:
      Empty.			
      One.			
      More than one.			
      Longer than the file.	
  Presence of enclosing quotes:
      Not enclosed.			
      Enclosed.
      Incorrect.		
  Presence of blanks:
      None.
      One.				
      Many.				
  Presence of quotes within the pattern:
      None.
      One.				
      Many.			

# Filename
  Presence of a file corresponding to the name:
      Not present.		
      Present.
''');

    complexTslFile2 = File('test/2_complex_sample.tsl');
    complexTslFile2.writeAsStringSync('''
# File
  Size:
      Empty.			[property emptyfile] 
      Not empty.
  Number of occurrences of the pattern in the file:
      None.			[if !emptyfile] [property noOccurences]
      One.				[if !emptyfile]
      Many.				[if !emptyfile]
  Number of occurrences of the pattern in one line:
      One.				[if !noOccurences && !emptyfile]
      Many.			[if !noOccurences && !emptyfile]
  Position of the pattern in the file:
      First line.		[if !emptyfile]
      Last line.		[if !emptyfile]
      Any.				[if !emptyfile]

# Pattern
  Length of the pattern:
      Empty.			[property emptypattern]
      One.			
      More than one.			[property patternlengthgt1]
      Longer than the file.	
  Presence of enclosing quotes:
      Not enclosed.			[if !emptypattern]
      Enclosed.
      Incorrect.		
  Presence of blanks:
      None.
      One.				[if !emptypattern]
      Many.				[if !emptypattern && patternlengthgt1]
  Presence of quotes within the pattern:
      None.
      One.				[if !emptypattern]
      Many.			[if !emptypattern && patternlengthgt1]

# Filename
  Presence of a file corresponding to the name:
      Not present.		
      Present.
''');

    complexTslFile3 = File('test/3_complex_sample.tsl');
    complexTslFile3.writeAsStringSync('''
# File
  Size:
      Empty.			        [property emptyfile] 
      Not empty.
  Number of occurrences of the pattern in the file:
      None.			        [if !emptyfile] [property noOccurences]
      One.				[if !emptyfile]
      Many.				[if !emptyfile]
  Number of occurrences of the pattern in one line:
      One.				[if !noOccurences && !emptyfile]
      Many.			        [if !noOccurences && !emptyfile]
  Position of the pattern in the file:
      First line.		        [if !emptyfile]
      Last line.		        [if !emptyfile]
      Any.				[if !emptyfile]

# Pattern
  Length of the pattern:
      Empty.			        [property emptypattern]
      One.			        
      More than one.			[property patternlengthgt1]
      Longer than the file.	        
  Presence of enclosing quotes:
      Not enclosed.			[if !emptypattern]
      Enclosed.
      Incorrect.		[error]
  Presence of blanks:
      None.
      One.				[if !emptypattern]
      Many.				[if !emptypattern && patternlengthgt1]
  Presence of quotes within the pattern:
      None.
      One.				[if !emptypattern]
      Many.			        [if !emptypattern && patternlengthgt1]

# Filename
  Presence of a file corresponding to the name:
      Not present.		[error]
      Present.
''');

    complexTslFile4 = File('test/4_complex_sample.tsl');
    complexTslFile4.writeAsStringSync('''
# File
  Size:
      Empty.			[single][property emptyfile] 
      Not empty.
  Number of occurrences of the pattern in the file:
      None.			[single][if !emptyfile] [property noOccurences]
      One.				[if !emptyfile]
      Many.				[if !emptyfile]
  Number of occurrences of the pattern in one line:
      One.				[if !noOccurences && !emptyfile]
      Many.			[single][if !noOccurences && !emptyfile]
  Position of the pattern in the file:
      First line.		[single][if !emptyfile]
      Last line.		[single][if !emptyfile]
      Any.				[if !emptyfile]

# Pattern
  Length of the pattern:
      Empty.			[single][property emptypattern]
      One.			[single]
      More than one.			[property patternlengthgt1]
      Longer than the file.	[single]
  Presence of enclosing quotes:
      Not enclosed.			[if !emptypattern]
      Enclosed.
      Incorrect.		[error]
  Presence of blanks:
      None.
      One.				[if !emptypattern]
      Many.				[if !emptypattern && patternlengthgt1]
  Presence of quotes within the pattern:
      None.
      One.				[if !emptypattern]
      Many.			[single][if !emptypattern && patternlengthgt1]

# Filename
  Presence of a file corresponding to the name:
      Not present.		[error]
      Present.
''');
  });

  tearDown(() {
    if (simpleTslFile1.existsSync()) {
      simpleTslFile1.deleteSync();
    }
    if (complexTslFile1.existsSync()) {
      complexTslFile1.deleteSync();
    }
    if (complexTslFile2.existsSync()) {
      complexTslFile2.deleteSync();
    }
    if (complexTslFile3.existsSync()) {
      complexTslFile3.deleteSync();
    }
    if (complexTslFile4.existsSync()) {
      complexTslFile4.deleteSync();
    }
  });

  test('Generates exact 16 frames for simple TSL example 1', () {
    final parser = TslParser(simpleTslFile1);
    final categories = parser.parse();

    final generator = FrameGenerator(categories);
    final frames = generator.generate();

    // Debug output
    print('Total frames: ${frames.totalFrames}');
    print(
      'Single/error frames: ${frames.singleFrames + frames.errorFrames}',
    );

    expect(
      frames.totalFrames,
      equals(16),
      reason: 'Complex TSL should generate exactly 16 frames',
    );
  });

  test('Generates exact 7776 frames for complex TSL example 1', () {
    final parser = TslParser(complexTslFile1);
    final categories = parser.parse();

    final generator = FrameGenerator(categories);
    final frames = generator.generate();

    // Debug output
    print('Total frames: ${frames.totalFrames}');
    print(
      'Single/error frames: ${frames.singleFrames + frames.errorFrames}',
    );

    expect(
      frames.totalFrames,
      equals(7776),
      reason: 'Complex TSL should generate exactly 7776 frames',
    );
  });

  test('Generates exact 1696 frames for complex TSL example 2', () {
    final parser = TslParser(complexTslFile2);
    final categories = parser.parse();

    final generator = FrameGenerator(categories);
    final frames = generator.generate();

    // Debug output
    print('Total frames: ${frames.totalFrames}');
    print(
      'Single/error frames: ${frames.singleFrames + frames.errorFrames}',
    );

    expect(
      frames.totalFrames,
      equals(1696),
      reason: 'Complex TSL should generate exactly 1696 frames',
    );
  });
  test('Generates exact 562 frames for complex TSL example 3', () {
    final parser = TslParser(complexTslFile3);
    final categories = parser.parse();

    final generator = FrameGenerator(categories);
    final frames = generator.generate();

    // Debug output
    print('Total frames: ${frames.totalFrames}');
    print(
      'Single/error frames: ${frames.singleFrames + frames.errorFrames}',
    );

    expect(
      frames.totalFrames,
      equals(562),
      reason: 'Complex TSL should generate exactly 562 frames',
    );
  });

  test('Generates exact 35 frames for complex TSL example 4', () {
    final parser = TslParser(complexTslFile4);
    final categories = parser.parse();

    final generator = FrameGenerator(categories);
    final frames = generator.generate();

    // Debug output
    print('Total frames: ${frames.totalFrames}');
    print(
      'Single/error frames: ${frames.singleFrames + frames.errorFrames}',
    );

    expect(
      frames.totalFrames,
      equals(35),
      reason: 'Complex TSL should generate exactly 35 frames',
    );
  });

  test('Fails to parse non-defined properties', () {
    final invalidTslFile = File('test/invalid_props.tsl');
    invalidTslFile.writeAsStringSync('''
# Complex expressions

  Category:
    Choice1.          [if A && B || C]
    Choice2.          [if !(A && B)]
    Choice3.          [if A && (B || C)]
    Choice4.          [if !(!A || B) && C || D]
''');

    try {
      final parser = TslParser(invalidTslFile);
      expect(() => parser.parse(), throwsA(isA<TslParserException>()));
    } finally {
      if (invalidTslFile.existsSync()) {
        invalidTslFile.deleteSync();
      }
    }
  });
}
