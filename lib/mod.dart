import 'dart:collection' as collection;

import 'package:source_span/source_span.dart';
import 'package:yaml/src/equality.dart';
import 'package:yaml/yaml.dart';

dynamic loadYaml = (String yaml) {
  var contents = loadYamlNode(yaml);
  return _modifiedYamlNodeFrom(contents, yaml);
};

class CONFIG {
  static const DEFAULT_INDENTATION = 2;
}

_ModifiableYamlNode _yamlReplaceRange(
    String yaml, int start, int end, String replacement) {
  var updatedYAML = yaml.replaceRange(start, end, replacement);
  var contents = loadYamlNode(yaml);
  return _modifiedYamlNodeFrom(contents, updatedYAML);
}

/// An interface for modifiable YAML nodes from a YAML AST.
// On top of the [YamlNode] elements, [_ModifiableYamlNode] also
// has the base [_YAML] object so that we can imitate modifications.
abstract class _ModifiableYamlNode extends YamlNode {
  /// Original YAML string from which this instance is constructed.
  String yaml;

  SourceSpan _span;
  int get startOffset => _span.start.offset;

  @override
  SourceSpan get span => _span;

  _ModifiableYamlNode(this.yaml);

  // MARK - methods below modify the yaml string. Note that start and end
  // should already be relative to the yaml string.
  _ModifiableYamlNode _replaceRange(int start, int end, String replacement) {
    var updatedYaml = yaml.replaceRange(start, end, replacement);

    var contents = loadYamlNode(updatedYaml);
    return _modifiedYamlNodeFrom(contents, updatedYaml);
  }

  _ModifiableYamlNode _removeRange(int start, int end) =>
      _replaceRange(start, end, '');

  _ModifiableYamlNode _replaceRangeFromSpan(
      SourceSpan span, String replacement) {
    var start = span.start.offset;
    var end = span.end.offset;
    return _replaceRange(start, end, replacement);
  }

  _ModifiableYamlNode _yamlInsert(int offset, String replacement) {
    return _replaceRange(offset, offset, replacement);
  }

  @override
  String toString() => yaml;
}

_ModifiableYamlNode _modifiedYamlNodeFrom(YamlNode node, String yaml) {
  switch (node.runtimeType) {
    case YamlList:
      return _ModifiableYamlList.from(node as YamlList, yaml);
    case YamlMap:
      return _ModifiableYamlMap.from(node as YamlMap, yaml);
    case YamlScalar:
      return _ModifiableYamlScalar.from(node as YamlScalar, yaml);
    case _ModifiableYamlList:
    case _ModifiableYamlMap:
    case _ModifiableYamlScalar:
      return (node as _ModifiableYamlNode);
    default:
      throw UnsupportedError(
          'Cannot create ModifiableYamlNode from ${node.runtimeType}');
  }
}

class _ModifiableYamlScalar extends _ModifiableYamlNode {
  /// The [YamlScalar] from which this instance was created.
  final YamlScalar _yamlScalar;

  @override
  dynamic get value => _yamlScalar.value;

  _ModifiableYamlScalar.from(this._yamlScalar, String yaml) : super(yaml) {
    _span = _yamlScalar.span;
  }

  @override
  String toString() => yaml;
}

class _ModifiableYamlList extends _ModifiableYamlNode {
  List<_ModifiableYamlNode> nodes;
  CollectionStyle style;

  int get length => nodes.length;

  set length(int index) =>
      throw UnsupportedError("This method shouldn't be called!");

  @override
  List get value => nodes;

  _ModifiableYamlList.from(YamlList yamlList, String yaml) : super(yaml) {
    _span = yamlList.span;
    style = yamlList.style;

    nodes = [];
    for (var node in yamlList.nodes) {
      var start = node.span.start.offset;
      var end = node.span.end.offset;

      var nodeYAML = yaml.substring(start - startOffset, end - startOffset);
      nodes.add(_modifiedYamlNodeFrom(node, nodeYAML));
    }
  }

  /// Gets the indentation level of the list. This is 0 if it is a flow list,
  /// but returns the number of spaces before the hyphen of elements for
  /// block lists.
  int get indentation {
    if (style == CollectionStyle.FLOW) return 0;

    if (nodes.isEmpty) {
      throw UnsupportedError('Unable to get indentation for empty block list');
    }

    var lastSpanOffset = nodes.last.span.start.offset;
    var lastNewLine = yaml.lastIndexOf('\n', lastSpanOffset);
    if (lastNewLine == -1) lastNewLine = 0;
    var lastHyphen = yaml.lastIndexOf('-', lastSpanOffset);

    return lastHyphen - lastNewLine - 1;
  }

  _ModifiableYamlNode operator [](int index) => nodes[index];

  // TODO(walnut): tidy this up - Maybe create a _ModifiableYamlCollection
  _ModifiableYamlNode setIn(index, newValue) {
    if (index is int) {
      var currValue = nodes[index];
      // TODO(walnut): list/map new values
      return _replaceRangeFromSpan(currValue._span, newValue.toString());
    }

    if (index is List && index[0] is int) {
      var idx = index[0] as int;

      if (nodes[idx] is _ModifiableYamlMap) {
        if (index.length == 1) {
          return (nodes[idx] as _ModifiableYamlMap).setIn(idx, newValue);
        }

        return (nodes[idx] as _ModifiableYamlMap)
            .setIn(index.sublist(1), newValue);
      }

      if (nodes[idx] is _ModifiableYamlList) {
        if (index.length == 1) {
          return (nodes[idx] as _ModifiableYamlList).setIn(idx, newValue);
        }
        return (nodes[idx] as _ModifiableYamlList)
            .setIn(index.sublist(1), value);
      }
    }

    throw UnsupportedError('Invalid index $index supplied to setIn');
  }

  _ModifiableYamlNode removeAt(int index) {
    var removedNode = nodes.removeAt(index);

    if (style == CollectionStyle.FLOW) {
      return removeFromFlowList(removedNode._span, index);
    } else {
      return removeFromBlockList(removedNode._span);
    }
  }

  _ModifiableYamlNode remove(Object elem) {
    var index = indexOf(elem);
    if (index == -1) return this;

    return removeAt(index);
  }

  _ModifiableYamlNode add(Object elem) {
    if (style == CollectionStyle.FLOW) {
      return addToFlowList(elem);
    } else {
      return addToBlockList(elem);
    }
  }

  _ModifiableYamlNode removeFromFlowList(SourceSpan span, int index) {
    var start = span.start.offset;
    var end = span.end.offset;

    if (index == 0) {
      start = yaml.lastIndexOf('[', start) + 1;
      end = yaml.indexOf(RegExp(r',|]'), end) + 1;
    } else {
      start = yaml.lastIndexOf(',', start);
    }
    return _replaceRange(start, end, '');
  }

  _ModifiableYamlNode removeFromBlockList(SourceSpan span) {
    var start = yaml.lastIndexOf('\n', span.start.offset);
    var end = yaml.indexOf('\n', span.end.offset);
    return _replaceRange(start, end, '');
  }

  /// Overriding indexOf to provide deep equality, allowing users to remove
  /// elements by the values rather than requiring them to construct
  /// [_ModifiableYamlNode]s
  int indexOf(Object element, [int start = 0]) {
    if (start < 0) start = 0;
    for (var i = start; i < length; i++) {
      if (deepEquals(this[i].value, element)) return i;
    }
    return -1;
  }

  _ModifiableYamlNode addToFlowList(Object elem) {
    var valueString = getFlowString(elem);
    if (nodes.isNotEmpty) valueString = ', ' + valueString;

    return _yamlInsert(span.end.offset - 1, valueString);
  }

  _ModifiableYamlNode addToBlockList(Object elem) {
    var valueString =
        getBlockString(elem, indentation + CONFIG.DEFAULT_INDENTATION);
    var formattedValue = ''.padLeft(indentation) + '- ';

    if (isCollection(elem)) {
      formattedValue +=
          valueString.substring(indentation + CONFIG.DEFAULT_INDENTATION) +
              '\n';
    } else {
      formattedValue += valueString + '\n';
    }
    return _replaceRange(span.end.offset, span.end.offset, formattedValue);
  }

  @override
  String toString() => yaml;
}

class _ModifiableYamlMap extends _ModifiableYamlNode {
  int get length => nodes.length;

  Map<dynamic, _ModifiableYamlNode> nodes;

  CollectionStyle style;

  @override
  String toString() => yaml;

  /// Gets the indentation level of the map. This is 0 if it is a flow map,
  /// but returns the number of spaces before the keys for block maps.
  int get indentation {
    if (style == CollectionStyle.FLOW) return 0;

    if (nodes.isEmpty) {
      throw UnsupportedError('Unable to get indentation for empty block list');
    }

    var lastKey = nodes.keys.last as YamlNode;
    var lastSpanOffset = lastKey.span.start.offset - startOffset;
    var lastNewLine = yaml.lastIndexOf('\n', lastSpanOffset);
    if (lastNewLine == -1) lastNewLine = 0;

    return lastSpanOffset - lastNewLine - 1;
  }

  _ModifiableYamlMap.from(YamlMap yamlMap, String yaml) : super(yaml) {
    _span = yamlMap.span;
    style = yamlMap.style;

    nodes = deepEqualsMap<dynamic, _ModifiableYamlNode>();
    for (var entry in yamlMap.nodes.entries) {
      var start = entry.value.span.start.offset - startOffset;
      var end = entry.value.span.end.offset - startOffset;

      var valueYaml = yaml.substring(start, end);
      nodes[entry.key] = _modifiedYamlNodeFrom(entry.value, valueYaml);
    }
  }

  _ModifiableYamlNode operator [](key) => nodes[key];

  // ?(walnut): are arrays acceptable yaml keys?
  _ModifiableYamlNode setIn(key, newValue) {
    if (key is List) {
      var idx = key[0];

      if (key.length == 1) {
        return setIn(idx, newValue);
      }

      if (nodes[idx] is _ModifiableYamlMap) {
        var updatedValue =
            (nodes[idx] as _ModifiableYamlMap).setIn(key.sublist(1), newValue);
        return setIn(idx, updatedValue);
      }

      if (nodes[idx] is _ModifiableYamlList) {
        var updatedValue =
            (nodes[idx] as _ModifiableYamlList).setIn(key.sublist(1), newValue);
        return setIn(idx, updatedValue);
      }

      throw UnsupportedError('Unable to perform setIn on a scalar!');
    }

    if (!nodes.containsKey(key)) {
      if (style == CollectionStyle.FLOW) {
        return addToFlowMap(key, newValue);
      } else {
        return addToBlockMap(key, newValue);
      }
    } else {
      if (style == CollectionStyle.FLOW) {
        return replaceInFlowMap(key, newValue);
      } else {
        return replaceInBlockMap(key, newValue);
      }
    }
  }

  YamlNode getKeyNode(Object key) {
    return (nodes.keys.firstWhere((node) => node.value == key) as YamlNode);
  }

  _ModifiableYamlNode remove(Object key) {
    if (!nodes.containsKey(key)) return null;

    var keyNode =
        (nodes.keys.firstWhere((node) => node.value == key) as YamlNode);
    var valueNode = nodes.remove(key);

    if (style == CollectionStyle.FLOW) {
      return removeFromFlowMap(keyNode.span, valueNode.span, key);
    } else {
      return removeFromBlockMap(keyNode.span, valueNode.span);
    }
  }

  @override
  Map get value => nodes;

  _ModifiableYamlNode addToFlowMap(Object key, Object newValue) {
    // The -1 accounts for the closing bracket.
    if (nodes.isEmpty) {
      return _yamlInsert(span.end.offset - 1 - startOffset, '$key: $newValue');
    } else {
      return _yamlInsert(
          span.end.offset - 1 - startOffset, ', $key: $newValue');
    }
  }

  _ModifiableYamlNode addToBlockMap(Object key, Object newValue) {
    var valueString =
        getBlockString(newValue, indentation + CONFIG.DEFAULT_INDENTATION);
    var formattedValue = ' ' * indentation + '$key: ';
    var offset = span.end.offset - startOffset;

    // Adjusts offset to after the trailing newline of the last entry, if it exists
    if (nodes.isNotEmpty) {
      var lastValueSpanEnd = nodes.values.last._span.end.offset - startOffset;
      var nextNewLineIndex = yaml.indexOf('\n', lastValueSpanEnd);

      if (nextNewLineIndex != -1) offset = nextNewLineIndex + 1;
    }

    if (isCollection(newValue)) formattedValue += '\n';

    formattedValue += valueString + '\n';
    return _yamlInsert(offset, formattedValue);
  }

  _ModifiableYamlNode replaceInFlowMap(Object key, Object newValue) {
    var valueSpan = nodes[key].span;
    var valueString = getFlowString(newValue);

    if (isCollection(newValue)) valueString = '\n' + valueString;
    return _replaceRangeFromSpan(valueSpan, valueString);
  }

  _ModifiableYamlNode replaceInBlockMap(Object key, Object newValue) {
    var value = nodes[key];
    var valueString =
        getBlockString(newValue, indentation + CONFIG.DEFAULT_INDENTATION);
    var start = getKeyNode(key).span.end.offset + 2 - startOffset;
    print(key);
    print(getKeyNode(key).span.end.offset);

    var end = _getContentSensitiveEnd(value) - startOffset;

    if (isCollection(newValue)) valueString = '\n' + valueString;
    print(yaml.replaceRange(start, end, valueString));
    return _replaceRange(start, end, valueString);
  }

  void clear() => _replaceRangeFromSpan(span, '');

  Iterable get keys => nodes.keys.map((node) => node.value);

  _ModifiableYamlNode removeFromFlowMap(
      SourceSpan keySpan, SourceSpan valueSpan, Object key) {
    var start = keySpan.start.offset;
    var end = valueSpan.end.offset;

    if (deepEquals(key, nodes.keys.first)) {
      start = yaml.lastIndexOf('{', start) + 1;
      end = yaml.indexOf(RegExp(r',|}'), end) + 1;
    } else {
      start = yaml.lastIndexOf(',', start);
    }

    return _removeRange(start, end);
  }

  _ModifiableYamlNode removeFromBlockMap(
      SourceSpan keySpan, SourceSpan valueSpan) {
    var start = yaml.lastIndexOf('\n', keySpan.start.offset);
    var end = yaml.indexOf('\n', valueSpan.end.offset);
    return _removeRange(start, end);
  }
}

/// Returns a safe string by checking for strings that begin with > or |
String getSafeString(String string) {
  if (string.startsWith('>') || string.startsWith('|')) {
    return '\'$string\'';
  }

  return string;
}

/// Returns values as strings representing flow objects.
String getFlowString(Object value) {
  return getSafeString(value.toString());
}

/// Returns values as strings representing block objects.
// We do a join('\n') rather than having it in the mapping to avoid
// adding additional spaces when updating rather than adding elements.
String getBlockString(Object value, [int indentation = 0]) {
  if (value is List) {
    return value.map((e) => ' ' * indentation + '- $e').join('\n');
  } else if (value is Map) {
    return value.entries.map((entry) {
      var result = ' ' * indentation + '${entry.key}:';

      if (!isCollection(entry.value)) return result + ' ${entry.value}';

      return '$result\n' +
          getBlockString(entry.value, indentation + CONFIG.DEFAULT_INDENTATION);
    }).join('\n');
  }

  return getSafeString(value.toString());
}

/// Returns the content sensitive ending offset of a node (i.e. where the last
/// meaningful content happens)
int _getContentSensitiveEnd(_ModifiableYamlNode node) {
  if (node is _ModifiableYamlList) {
    return _getContentSensitiveEnd(node.value.last as _ModifiableYamlNode);
  } else if (node is _ModifiableYamlMap) {
    return _getContentSensitiveEnd(
        node.value.values.last as _ModifiableYamlNode);
  }

  return node.span.end.offset;
}

bool isCollection(Object item) => item is Map || item is List;
