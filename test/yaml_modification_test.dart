import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('accurately reproduces:', () {
    group('string -', () {
      test('simple ', () {
        expect(loadYamlDocument('foo').dump(), equals('foo'));
      });

      test('simple with comment', () {
        expect(
            loadYamlDocument('foo # comment').dump(), equals('foo # comment'));
      });

      test('unicode', () {
        expect(loadYamlDocument('"Sosa did fine.\u263A"').dump(),
            equals('"Sosa did fine.\u263A"'));
      });

      test('double-quoted with comment', () {
        expect(loadYamlDocument('"Sosa did fine.\u263A" # comment').dump(),
            equals('"Sosa did fine.\u263A" # comment'));
      });

      test('control', () {
        expect(loadYamlDocument('"\b1998\t1999\t2000\n"').dump(),
            equals('"\b1998\t1999\t2000\n"'));
      });
      test('hex escaped', () {
        expect(loadYamlDocument('"\x0d\x0a is \r\n"').dump(),
            equals('"\x0d\x0a is \r\n"'));
      });
      test('single-quoted', () {
        expect(loadYamlDocument('\'"Howdy!" he cried.\'').dump(),
            equals('\'"Howdy!" he cried.\''));
      });

      test('single-quoted with comment', () {
        expect(loadYamlDocument('\'"Howdy!" he cried.\' # comment').dump(),
            equals('\'"Howdy!" he cried.\' # comment'));
      });

      test('tie-fighter', () {
        expect(loadYamlDocument('\'|\-*-/|\'').dump(), equals('\'|\-*-/|\''));
      });

      test('folded', () {
        expect(loadYamlDocument('''
>
      Mark set a major league
      home run record in 1998.''').dump(), equals('''
>
      Mark set a major league
      home run record in 1998.'''));
      });

      test('folded with comment', () {
        expect(loadYamlDocument('''
> # comment
      Mark set a major league
      home run record in 1998.''').dump(), equals('''
> # comment
      Mark set a major league
      home run record in 1998.'''));
      });

      test('plain', () {
        expect(loadYamlDocument('''
Mark set a major league
      home run record in 1998.''').dump(), equals('''
Mark set a major league
      home run record in 1998.'''));
      });

      test('literal', () {
        expect(loadYamlDocument('''
|
      Mark set a major league
      home run record in 1998.''').dump(), equals('''
|
      Mark set a major league
      home run record in 1998.'''));
      });

      test('literal with comment', () {
        expect(loadYamlDocument('''
| # comment
      Mark set a major league
      home run record in 1998.''').dump(), equals('''
| # comment
      Mark set a major league
      home run record in 1998.'''));
      });
    });

    group('number -', () {
      test('simple', () {
        expect(loadYamlDocument('1').dump(), equals('1'));
      });

      test('simple with comment', () {
        expect(loadYamlDocument('1 # comment').dump(), equals('1 # comment'));
      });

      test('simple negative', () {
        expect(loadYamlDocument('-1').dump(), equals('-1'));
      });

      test('simple floating point', () {
        expect(loadYamlDocument('345.678').dump(), equals('345.678'));
      });
      test('simple hexadecimal', () {
        expect(loadYamlDocument('0x123abc').dump(), equals('0x123abc'));
      });
      test('simple exponential', () {
        expect(loadYamlDocument('12.3015e+02').dump(), equals('12.3015e+02'));
      });

      test('simple octal', () {
        expect(loadYamlDocument('0o14').dump(), equals('0o14'));
      });
    });

    group('map -', () {
      test('simple block ', () {
        expect(loadYamlDocument('foo: bar').dump(), equals('foo: bar'));
      });

      test('simple block (2)', () {
        expect(loadYamlDocument('foo: bar\nbar: baz').dump(),
            equals('foo: bar\nbar: baz'));
      });

      test('simple block with comments', () {
        expect(loadYamlDocument('foo: bar # comment\nbar: baz').dump(),
            equals('foo: bar # comment\nbar: baz'));
      });

      test('nested block with comments', () {
        expect(loadYamlDocument('a: # comment\n  b:\n    c: 2').dump(),
            equals('a: # comment\n  b:\n    c: 2'));
      });

      test('nested block with comments (2)', () {
        expect(loadYamlDocument('''
map: # comment
  a: 
    b: 1

    # comment

    c: { d: 3 , e: 4 } # comment
    d: 1 # comment

    # comment

    e: 3
''').dump(), equals('''
map: # comment
  a: 
    b: 1

    # comment

    c: { d: 3 , e: 4 } # comment
    d: 1 # comment

    # comment

    e: 3
'''));
      });

      test('simple flow', () {
        expect(loadYamlDocument('{foo: bar}').dump(), equals('{foo: bar}'));
      });

      // TODO(walnut): spaces after keys are not detected
      test('simple flow (2)', () {
        expect(loadYamlDocument('{  foo: bar, bar:  baz }').dump(),
            equals('{  foo: bar, bar:  baz }'));
      });

      test('simple flow with comments', () {
        expect(loadYamlDocument('{foo: bar} # comments').dump(),
            equals('{foo: bar} # comments'));
      });
    });

    group('array -', () {
      test('simple block', () {
        expect(loadYamlDocument('- 1').dump(), equals('- 1'));
      });

      // TODO(walnut): this had one extra new line each. this happens only if the
      // array is at the base of the document.
      // test('simple block (2)', () {
      //   expect(
      //       loadYamlDocument('- 1\n- 2\n- 3').dump(), equals('- 1\n- 2\n- 3'));
      // });

      // TODO(walnut): not yet able to read comments between array elements
      // test('simple block (3)', () {
      //   expect(loadYamlDocument('- 1\n- 2\n# comment\n- 3').dump(),
      //       equals('- 1\n- 2\n- 3'));
      // });

      test('simple flow', () {
        expect(loadYamlDocument('[1]').dump(), equals('[1]'));
      });

      test('simple flow (2)', () {
        expect(loadYamlDocument('[ 1 , 2, 3 ]').dump(), equals('[ 1 , 2, 3 ]'));
      });

      test('simple flow with comments', () {
        expect(loadYamlDocument('[1, 2] # comment').dump(),
            equals('[1, 2] # comment'));
      });
    });

    group('map-array', () {
      test('', () {
        expect(loadYamlDocument('''
list:
  - 1 # comment
  - 2
recipe:
  - verb: Score # comment
    outputs: [ "DishOffering[]/Scored" , "Dishes" ] # comment
    name: Hotpot # comment
  - verb: Rate
    inputs: "Dish" # comment
    outputs: [ "DishOffering[]/Rated" ]
''').dump(), equals('''
list:
  - 1 # comment
  - 2
recipe:
  - verb: Score # comment
    outputs: [ "DishOffering[]/Scored" , "Dishes" ] # comment
    name: Hotpot # comment
  - verb: Rate
    inputs: "Dish" # comment
    outputs: [ "DishOffering[]/Rated" ]'''));
      });
    });
  });
}
