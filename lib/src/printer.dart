import 'package:yaml/src/style.dart';

import 'yaml_node.dart';

class _PositionAwareBuffer {
  final StringBuffer buffer = StringBuffer();

  int column = 0;
  int line = 0;

  _PositionAwareBuffer();

  void write(Object obj) {
    var s = obj.toString();
    line += '\n'.allMatches(s).length;
    column = s.length - s.lastIndexOf('\n') - 1;

    buffer.write(s);
  }

  @override
  String toString() {
    return buffer.toString();
  }
}

class Printer {
  /// The contents of the document.
  final YamlNode contents;

  final _PositionAwareBuffer buffer = _PositionAwareBuffer();

  Printer(this.contents);

  void _loadBlockMap(YamlMap map) {
    map.nodes.entries.forEach((entry) {
      if (buffer.column == 0) {
        var indentation = map.span.start.column;
        var spaces = List.filled(indentation, ' ').join('');
        buffer.write(spaces);
      }
      buffer.write('${entry.key}: ');
      if (entry.value is YamlCollection &&
          (entry.value as YamlCollection).style == CollectionStyle.BLOCK) {
        buffer.write('\n');
      }
      _loadNode(entry.value);

      if (entry.key != map.nodes.entries.last.key) {
        buffer.write('\n');
      }
    });
  }

  void _loadMap(YamlMap map) {
    switch (map.style) {
      case CollectionStyle.BLOCK:
        _loadBlockMap(map);
        break;
      default: // Treat the default case as a flow map
        buffer.write('non-block map');
        break;
    }
  }

  void _loadBlockList(YamlList list) {
    var indentation = list.span.start.column;
    var spaces = List.filled(indentation, ' ').join('');

    list.nodes.forEach((node) {
      buffer.write('$spaces- ');
      // TODO
      if (node is YamlCollection && node.style == CollectionStyle.BLOCK) {
        // buffer.write('\n');
      }
      _loadNode(node);

      if (node != list.nodes.last) {
        buffer.write('\n');
      }
    });
  }

  void _loadFlowList(YamlList list) {
    buffer.write('[');

    list.nodes.forEach((node) {
      _loadNode(node);

      if (node != list.nodes.last) {
        buffer.write(',');
      }
    });

    buffer.write(']');
  }

  void _loadList(YamlList list) {
    switch (list.style) {
      case CollectionStyle.BLOCK:
        _loadBlockList(list);
        break;
      default: // Treat the default case as a flow list
        _loadFlowList(list);
        break;
    }
  }

  void _loadScalar(YamlScalar scalar) {
    // TODO(walnut): long strings do not retain their indentation
    switch (scalar.style) {
      case ScalarStyle.FOLDED:
        buffer.write('>\n${scalar.originalString}');
        break;
      case ScalarStyle.LITERAL:
        buffer.write('|\n${scalar.originalString}');
        break;
      default:
        buffer.write('${scalar.originalString}');
        break;
    }
  }

  void _loadNode(YamlNode node) {
    switch (node.runtimeType) {
      case YamlScalar:
        _loadScalar(node as YamlScalar);
        break;
      case YamlList:
        _loadList(node as YamlList);
        break;
      case YamlMap:
        _loadMap(node as YamlMap);
        break;
      default:
        buffer.write('${node.runtimeType}');
        break;
    }
  }

  @override
  String toString() {
    _loadNode(contents);

    return buffer.toString();
  }
}
