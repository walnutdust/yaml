import 'package:test/test.dart';
import 'package:yaml/mod.dart';

void main() {
  group('undo', () {
    test('works for one action', () {
      var doc = loadYaml('{a: 1, b: 2, c: 3}');

      expect(doc.canUndo(), false);

      doc.remove('b');

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canUndo(), true);

      doc.undo();

      expect(doc.toString(), '{a: 1, b: 2, c: 3}');
      expect(doc.canUndo(), false);
    });

    test('works for two actions', () {
      var doc = loadYaml('{a: 1, b: 2, c: 3}');

      expect(doc.canUndo(), false);

      doc.remove('b');

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canUndo(), true);

      doc.remove('c');

      expect(doc.toString(), '{a: 1}');
      expect(doc.canUndo(), true);

      doc.undo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canUndo(), true);

      doc.undo();

      expect(doc.toString(), '{a: 1, b: 2, c: 3}');
      expect(doc.canUndo(), false);
    });
  });

  group('redo', () {
    test('works for one action', () {
      var doc = loadYaml('{a: 1, b: 2, c: 3}');

      expect(doc.canRedo(), false);

      doc.remove('b');

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);

      doc.undo();

      expect(doc.toString(), '{a: 1, b: 2, c: 3}');
      expect(doc.canRedo(), true);

      doc.redo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);
    });

    test('works for two actions', () {
      var doc = loadYaml('{a: 1, b: 2, c: 3}');

      expect(doc.canRedo(), false);

      doc.remove('b');

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);

      doc.remove('c');

      expect(doc.toString(), '{a: 1}');
      expect(doc.canRedo(), false);

      doc.undo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), true);

      doc.undo();

      expect(doc.toString(), '{a: 1, b: 2, c: 3}');
      expect(doc.canRedo(), true);

      doc.redo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), true);

      doc.redo();

      expect(doc.toString(), '{a: 1}');
      expect(doc.canRedo(), false);
    });

    test('works to keep redoing the same undo', () {
      var doc = loadYaml('{a: 1, b: 2, c: 3}');
      doc.remove('b');

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);

      doc.undo();
      doc.redo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);

      doc.undo();
      doc.redo();

      expect(doc.toString(), '{a: 1, c: 3}');
      expect(doc.canRedo(), false);
    });
  });
}
