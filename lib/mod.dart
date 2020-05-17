import 'dart:collection' as collection;

import 'package:source_span/source_span.dart';
import 'package:yaml/src/equality.dart';
import 'package:yaml/yaml.dart';

dynamic loadYaml = (String yaml) => _YAML(yaml);

class _YAML {
  String yaml;

  dynamic _contents;

  _YAML(this.yaml) {
    var contents = loadYamlNode(yaml);
    _contents = _modifiedYamlNodeFrom(contents, this);
  }

  dynamic operator [](key) => _contents[key];
  operator []=(key, value) => _contents[key] = value;

  dynamic remove(Object value) => _contents.remove(value);
  dynamic removeAt(int index) => _contents.removeAt(index);

  dynamic get value => _contents.value;

  void add(Object value) => _contents.add(value);

  void replaceRangeFromSpan(SourceSpan span, String replacement) {
    var start = span.start.offset;
    var end = span.end.offset;
    replaceRange(start, end, replacement);
  }

  void replaceRange(int start, int end, String replacement) {
    yaml = yaml.replaceRange(start, end, replacement);
    var contents = loadYamlNode(yaml);
    _contents = _modifiedYamlNodeFrom(contents, this);
  }

  @override
  String toString() => yaml;
}

abstract class _ModifiableYamlNode extends YamlNode {
  SourceSpan _span;

  @override
  SourceSpan get span => _span;

  _YAML _baseYaml;
}

_ModifiableYamlNode _modifiedYamlNodeFrom(YamlNode node, _YAML baseYaml) {
  switch (node.runtimeType) {
    case YamlList:
      return _ModifiableYamlList.from(node as YamlList, baseYaml);
    case YamlMap:
      return _ModifiableYamlMap.from(node as YamlMap, baseYaml);
    case YamlScalar:
      return _ModifiableYamlScalar.from(node as YamlScalar, baseYaml);
    default:
      throw UnimplementedError();
  }
}

class _ModifiableYamlScalar extends _ModifiableYamlNode {
  final YamlScalar _yamlScalar;
  @override
  dynamic get value => _yamlScalar.value;

  _ModifiableYamlScalar.from(this._yamlScalar, _YAML baseYaml) {
    _span = _yamlScalar.span;
    _baseYaml = baseYaml;
  }

  @override
  String toString() => _yamlScalar.value.toString();
}

class _ModifiableYamlList extends _ModifiableYamlNode
    with collection.ListMixin {
  List<_ModifiableYamlNode> nodes;

  @override
  int get length => nodes.length;
  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  CollectionStyle style;

  _ModifiableYamlList.from(YamlList yamlList, _YAML baseYaml) {
    _baseYaml = baseYaml;
    _span = yamlList.span;
    style = yamlList.style;

    nodes = [];
    for (var node in yamlList.nodes) {
      nodes.add(_modifiedYamlNodeFrom(node, _baseYaml));
    }
  }

  int get indentation {
    if (style == CollectionStyle.FLOW) {
      throw UnimplementedError('Unable to get indentation for flow list');
    }

    if (nodes.isEmpty) {
      throw UnimplementedError(
          'Unable to get indentation for empty block list');
    }

    var lastSpanOffset = nodes.last.span.start.offset;
    var lastNewLine = _baseYaml.yaml.lastIndexOf('\n', lastSpanOffset);
    if (lastNewLine == -1) lastNewLine = 0;
    var lastHyphen = _baseYaml.yaml.lastIndexOf('-', lastSpanOffset);

    return lastHyphen - lastNewLine - 1;
  }

  @override
  _ModifiableYamlNode operator [](int index) => nodes[index];

  @override
  void operator []=(int index, value) {
    var currValue = nodes[index];

    if (currValue == null) {
      // TODO(walnut): adding an element
    } else {
      // TODO(walnut): list/map new values
      _baseYaml.replaceRangeFromSpan(currValue._span, value.toString());
    }
  }

  void removeFromFlowList(SourceSpan span, int index) {
    var start = span.start.offset;
    var end = span.end.offset;

    if (index == 0) {
      start = _baseYaml.yaml.lastIndexOf('[', start) + 1;
      end = _baseYaml.yaml.indexOf(RegExp(r',|]'), end) + 1;
    } else {
      start = _baseYaml.yaml.lastIndexOf(',', start);
    }

    _baseYaml.replaceRange(start, end, '');
  }

  void removeFromBlockList(SourceSpan span) {
    var start = _baseYaml.yaml.lastIndexOf(RegExp(r'\n'), span.start.offset);
    var end = _baseYaml.yaml.indexOf(RegExp(r'\n'), span.end.offset);
    _baseYaml.replaceRange(start, end, '');
  }

  @override
  _ModifiableYamlNode removeAt(int index) {
    var removedNode = nodes.removeAt(index);

    if (style == CollectionStyle.FLOW) {
      removeFromFlowList(removedNode._span, index);
    } else {
      removeFromBlockList(removedNode._span);
    }

    return removedNode;
  }

  @override
  int indexOf(Object element, [int start = 0]) {
    if (start < 0) start = 0;
    for (var i = start; i < length; i++) {
      if (deepEquals(this[i].value, element)) return i;
    }
    return -1;
  }

  @override
  bool remove(Object value) {
    var index = indexOf(value);
    if (index == -1) return false;

    removeAt(index);
    return true;
  }

  void addToFlowList(Object value) {
    if (nodes.isEmpty) {
      _baseYaml.replaceRange(
          span.end.offset - 1, span.end.offset - 1, '$value');
    } else {
      _baseYaml.replaceRange(
          span.end.offset - 1, span.end.offset - 1, ', $value');
    }
  }

  void addToBlockList(Object value) {
    var valueString = ''.padLeft(indentation) + '- $value\n';
    _baseYaml.replaceRange(span.end.offset, span.end.offset, valueString);
  }

  @override
  void add(Object value) {
    if (style == CollectionStyle.FLOW) {
      addToFlowList(value);
    } else {
      addToBlockList(value);
    }
  }

  @override
  List get value => this;
}

class _ModifiableYamlMap extends _ModifiableYamlNode with collection.MapMixin {
  @override
  int length;

  Map<dynamic, _ModifiableYamlNode> nodes;

  CollectionStyle style;

  _ModifiableYamlMap.from(YamlMap yamlMap, _YAML baseYaml) {
    _span = yamlMap.span;
    _baseYaml = baseYaml;
    style = yamlMap.style;

    nodes = deepEqualsMap<dynamic, _ModifiableYamlNode>();
    for (var entry in yamlMap.nodes.entries) {
      nodes[entry.key] = _modifiedYamlNodeFrom(entry.value, baseYaml);
    }
  }

  @override
  _ModifiableYamlNode operator [](key) {
    return nodes[key];
  }

  @override
  void operator []=(key, value) {
    var currValue = nodes[key];

    if (currValue == null) {
      // TODO(walnut): adding an element
    } else {
      // TODO(walnut): list/map new values
      _baseYaml.replaceRangeFromSpan(currValue._span, value.toString());
    }
  }

  @override
  void clear() => _baseYaml.replaceRangeFromSpan(span, '');

  @override
  Iterable get keys => nodes.keys.map((node) => node.value);

  void removeFromFlowMap(SourceSpan keySpan, SourceSpan valueSpan, Object key) {
    var start = keySpan.start.offset;
    var end = valueSpan.end.offset;

    if (deepEquals(key, nodes.keys.first)) {
      start = _baseYaml.yaml.lastIndexOf('{', start) + 1;
      end = _baseYaml.yaml.indexOf(RegExp(r',|}'), end) + 1;
    } else {
      start = _baseYaml.yaml.lastIndexOf(',', start);
    }

    _baseYaml.replaceRange(start, end, '');
  }

  void removeFromBlockMap(SourceSpan keySpan, SourceSpan valueSpan) {
    var start = _baseYaml.yaml.lastIndexOf(RegExp(r'\n'), keySpan.start.offset);
    var end = _baseYaml.yaml.indexOf(RegExp(r'\n'), valueSpan.end.offset);
    _baseYaml.replaceRange(start, end, '');
  }

  @override
  _ModifiableYamlNode remove(Object key) {
    if (!nodes.containsKey(key)) return null;

    var keyNode =
        (nodes.keys.firstWhere((node) => node.value == key) as YamlNode);
    var valueNode = nodes.remove(key);

    if (style == CollectionStyle.FLOW) {
      removeFromFlowMap(keyNode.span, valueNode.span, key);
    } else {
      removeFromBlockMap(keyNode.span, valueNode.span);
    }

    return valueNode;
  }

  @override
  Map get value => this;
}
