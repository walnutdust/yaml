import 'package:yaml/src/style.dart';
import 'package:yaml/src/yaml_node_wrapper.dart';

import 'yaml_node.dart';

class _PositionAwareBuffer {
  final StringBuffer buffer = StringBuffer();

  int column = 0;
  int line = 0;

  _PositionAwareBuffer();

  void write(Object obj) {
    var s = obj.toString();
    var newLines = '\n'.allMatches(s).length;

    line += newLines;

    if (newLines > 0) {
      column = s.length - s.lastIndexOf('\n') - 1;
    } else {
      column += s.length;
    }

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

  final bool debug = false;

  Printer(this.contents);

  void _loadKey(dynamic key) {
    if (key is YamlNode) {
      _loadNode(key);
    } else {
      buffer.write(key);
    }
  }

  void _loadBlockMap(YamlMap map) {
    buffer.write(map.preContent);
    map.nodes.entries.forEach((entry) {
      if (buffer.column == 0) {
        var indentation = map.span.start.column;
        var spaces = List.filled(indentation, ' ').join('');
        buffer.write(spaces);
      }

      _loadKey(entry.key);
      buffer.write(':');

      if (entry.value is YamlList &&
          (entry.value as YamlList).style == CollectionStyle.BLOCK) {
        buffer.write('\n');
      }
      _loadNode(entry.value);
    });

    buffer.write(map.postContent);
  }

  void _loadFlowMap(YamlMap map) {
    buffer.write(map.preContent);
    buffer.write('{');

    map.nodes.entries.forEach((entry) {
      _loadKey(entry.key);
      buffer.write(':');
      _loadNode(entry.value);

      if (entry.key != map.nodes.entries.last.key) {
        buffer.write(',');
      }
    });

    buffer.write('}');
    buffer.write(map.postContent);
  }

  void _loadMap(YamlMap map) {
    switch (map.style) {
      case CollectionStyle.BLOCK:
        _loadBlockMap(map);
        break;
      default: // Treat the default case as a flow map
        _loadFlowMap(map);
        break;
    }
  }

  void _loadBlockList(YamlList list) {
    buffer.write(list.preContent);
    var indentation = list.span.start.column;
    var spaces = List.filled(indentation, ' ').join('');

    list.nodes.forEach((node) {
      if (node is YamlScalar && node.prePreContent.isNotEmpty) {
        buffer.write(node.prePreContent);
      } else {
        buffer.write(spaces);
      }
      buffer.write('-');
      _loadNode(node);
    });
    buffer.write(list.postContent);
  }

  void _loadFlowList(YamlList list) {
    buffer.write(list.preContent);
    buffer.write('[');

    list.nodes.forEach((node) {
      _loadNode(node);

      if (node != list.nodes.last) {
        buffer.write(',');
      }
    });

    buffer.write(']');
    buffer.write(list.postContent);
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
    switch (scalar.style) {
      case ScalarStyle.FOLDED:
      case ScalarStyle.LITERAL:
        buffer.write('${scalar.originalString}');
        break;
      default:
        buffer.write(
            '${scalar.preContent}${scalar.originalString}${scalar.postContent}');
        break;
    }
  }

  void _loadNode(YamlNode node) {
    if (debug) {
      buffer.write('/(${node.span.start.line},${node.span.start.column})');
    }
    switch (node.runtimeType) {
      case YamlScalar:
        _loadScalar(node as YamlScalar);
        break;
      case YamlList:
      case YamlListWrapper:
        _loadList(node as YamlList);
        break;
      case YamlMap:
      case YamlMapWrapper:
        _loadMap(node as YamlMap);
        break;
      default:
        buffer.write('_loadNode called with ${node.runtimeType}');
        break;
    }

    if (debug) {
      buffer.write('(${node.span.end.line},${node.span.end.column})/');
    }
  }

  @override
  String toString() {
    _loadNode(contents);

    return buffer.toString();
  }
}
