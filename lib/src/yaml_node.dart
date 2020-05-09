// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' as collection;

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import 'event.dart';
import 'null_span.dart';
import 'style.dart';
import 'yaml_node_wrapper.dart';

/// An interface for parsed nodes from a YAML source tree.
///
/// [YamlMap]s and [YamlList]s implement this interface in addition to the
/// normal [Map] and [List] interfaces, so any maps and lists will be
/// [YamlNode]s regardless of how they're accessed.
///
/// Scalars values like strings and numbers, on the other hand, don't have this
/// interface by default. Instead, they can be accessed as [YamlScalar]s via
/// [YamlMap.nodes] or [YamlList.nodes].
abstract class YamlNode {
  /// The source span for this node.
  ///
  /// [SourceSpan.message] can be used to produce a human-friendly message about
  /// this node.
  SourceSpan get span => _span;

  SourceSpan _span;

  /// The inner value of this node.
  ///
  /// For [YamlScalar]s, this will return the wrapped value. For [YamlMap] and
  /// [YamlList], it will return [this], since they already implement [Map] and
  /// [List], respectively.
  dynamic get value;

  /// The string that occured before this YamlMap
  String preContent;

  /// The string that occured after this YamlMap
  String postContent;

  YamlNode(this.preContent, this.postContent);

  static YamlNode from(dynamic value,
      {String preContent = '',
      String postContent = '',
      String indentation = ''}) {
    if (value is Map) {
      return YamlMap.from(value,
          style: CollectionStyle.BLOCK,
          postContent: postContent,
          indentation: indentation);
    }

    return YamlScalar.internalWithSpan(value, NullSpan.emptySpan(),
        preContent: preContent, postContent: postContent);
    // TODO(walnut): add list case
  }
}

abstract class YamlCollection extends YamlNode {
  /// The style used for the map in the original document.
  final CollectionStyle style;

  YamlCollection(this.style, [String preContent = '', String postContent = ''])
      : super(preContent, postContent);
}

/// A read-only [Map] parsed from YAML.
class YamlMap extends YamlCollection with collection.MapMixin {
  /// A view of [this] where the keys and values are guaranteed to be
  /// [YamlNode]s.
  ///
  /// The key type is `dynamic` to allow values to be accessed using
  /// non-[YamlNode] keys, but [Map.keys] and [Map.forEach] will always expose
  /// them as [YamlNode]s. For example, for `{"foo": [1, 2, 3]}` [nodes] will be
  /// a map from a [YamlScalar] to a [YamlList], but since the key type is
  /// `dynamic` `map.nodes["foo"]` will still work.
  final Map<dynamic, YamlNode> nodes;

  @override
  Map get value => this;

  @override
  Iterable get keys => nodes.keys.map((node) => node.value);

  /// Creates an empty YamlMap.
  ///
  /// This map's [span] won't have useful location information. However, it will
  /// have a reasonable implementation of [SourceSpan.message]. If [sourceUrl]
  /// is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap({sourceUrl}) => YamlMapWrapper(const {}, sourceUrl);

  /// Wraps a Dart map so that it can be accessed (recursively) like a
  /// [YamlMap].
  ///
  /// Any [SourceSpan]s returned by this map or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap.wrap(Map dartMap, {sourceUrl}) =>
      YamlMapWrapper(dartMap, sourceUrl);

  /// Like YamlMap.wrap, wraps a Dart map so it can be accessed recursively like a
  /// [YamlMap].
  ///
  /// Unlike YamlMap.wrap, the nodes are full fledged YamlNodes with meaningful
  /// preContent and postContent values. [SourceSpan]s are however still dummies.
  YamlMap.from(Map dartMap,
      {CollectionStyle style = CollectionStyle.ANY,
      String preContent = '',
      String postContent = '',
      String indentation = ''})
      : nodes = {},
        super(style, preContent, postContent) {
    _span = NullSpan.emptySpan();
    var entries = dartMap.entries;

    entries.forEach((entry) {
      var key = entry.key;
      var value = entry.value;

      var keyScalar = YamlScalar.internalWithSpan(
        key,
        NullSpan.emptySpan(),
        preContent: '\n    $indentation',
      );

      nodes[keyScalar] =
          YamlNode.from(value, preContent: ' ', indentation: '  ');
    });
  }

  /// Users of the library should not use this constructor.
  YamlMap.internal(this.nodes, SourceSpan span, CollectionStyle style,
      {String preContent = '', String postContent = ''})
      : super(style, preContent, postContent) {
    _span = span;
  }

  @override
  dynamic operator [](key) => nodes[key]?.value;

  @override
  void operator []=(key, value) {
    // TODO(walnut): Can only update to scalar at the moment.
    if (nodes.containsKey(key)) {
      var valueNode = nodes[key];

      var style = valueNode is YamlScalar ? valueNode.style : ScalarStyle.PLAIN;
      var preContent =
          valueNode.preContent.isEmpty ? ' ' : valueNode.preContent;

      var updatedScalar = YamlScalar.internalWithSpan(value, valueNode.span,
          originalString: value.toString(),
          style: style,
          preContent: preContent,
          postContent: valueNode.postContent);

      nodes[key] = updatedScalar;
    } else {
      // Default values for pre/post contents of key/value pair.
      var preContent = '\n';
      var postContent = '\n';

      // if the map is not empty, we can inherit the indentation
      // and post content from the last node
      if (nodes.isNotEmpty) {
        var lastEntry = nodes.entries.last;

        var lastKeyNode = (lastEntry.key as YamlNode);
        var lastValueNode = lastEntry.value;

        var lastNodePreContent = lastKeyNode.preContent;
        var lastNodePostContent = lastValueNode.postContent;

        // To get the indentation, find the last \n and work from there.
        var newLineIndex = lastNodePreContent.lastIndexOf('\n');
        if (newLineIndex != -1 &&
            newLineIndex < lastNodePreContent.length - 1) {
          preContent += lastNodePreContent.substring(newLineIndex + 1);
        }

        // We only want to inherit the post content if it is empty or is just spaces
        var trimmedString = lastNodePostContent.trimRight();
        if (trimmedString.isNotEmpty &&
            trimmedString.length != postContent.length) {
          postContent = lastNodePostContent.substring(trimmedString.length);
        }

        lastValueNode.postContent = trimmedString;
      }

      // Turn them into YamlScalars. Note the spans here are not really helpful.
      var keyScalar = YamlScalar.internalWithSpan(
        key,
        NullSpan(key.toString()),
        preContent: preContent,
      );

      if (value is Map) {
        nodes[keyScalar] = YamlMap.from(value,
            style: CollectionStyle.BLOCK, postContent: '\n$postContent');
      } else {
        nodes[keyScalar] = YamlScalar.internalWithSpan(
          value,
          NullSpan(value.toString()),
          preContent: ' ',
          postContent: postContent,
        );
      }
    }
  }

  @override
  void clear() => nodes.clear();

  @override
  dynamic remove(Object key) {
    var keyList = nodes.keys.toList();
    var keyNameList = nodes.keys.map((e) => e.toString()).toList();
    var index = keyNameList.indexOf(key.toString());

    // Note that this removal should not affect keyList
    var node = nodes.remove(key);

    // If there is a node beside it, we can "pass along" the pre/post contents.
    if (keyList.length > 1) {
      var nodeMeta = node.preContent;
      var newLineIndex = node.postContent.indexOf('\n');

      // ?(walnut): This assumes that we do not want comments on the same line.
      nodeMeta +=
          newLineIndex >= 0 && newLineIndex < node.postContent.length - 1
              ? node.postContent.substring(newLineIndex)
              : '';

      if (index == keyList.length - 1) {
        var prevNode = nodes[keyNameList[index - 1]];
        prevNode.postContent = prevNode.postContent + nodeMeta;
      } else {
        var nextNode = (keyList[index + 1] as YamlNode);
        nextNode.preContent = nodeMeta + nextNode.preContent;
      }
    }

    return node;
  }
}

/// A read-only [List] parsed from YAML.
class YamlList extends YamlCollection with collection.ListMixin {
  final List<YamlNode> nodes;

  @override
  List get value => this;

  @override
  int get length => nodes.length;

  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  /// Creates an empty YamlList.
  ///
  /// This list's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList({sourceUrl}) => YamlListWrapper(const [], sourceUrl);

  /// Wraps a Dart list so that it can be accessed (recursively) like a
  /// [YamlList].
  ///
  /// Any [SourceSpan]s returned by this list or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList.wrap(List dartList, {sourceUrl}) =>
      YamlListWrapper(dartList, sourceUrl);

  /// Users of the library should not use this constructor.
  YamlList.internal(
      List<YamlNode> nodes, SourceSpan span, CollectionStyle style,
      {String preContent = '', String postContent = ''})
      : nodes = UnmodifiableListView<YamlNode>(nodes),
        super(style, preContent, postContent) {
    _span = span;
  }

  @override
  dynamic operator [](int index) => nodes[index].value;

  @override
  operator []=(int index, value) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }
}

/// A wrapped scalar value parsed from YAML.
class YamlScalar extends YamlNode {
  @override
  final dynamic value;

  /// The style used for the scalar in the original document.
  final ScalarStyle style;

  /// The original string used to derive the [YamlScalar].
  final String originalString;

  final String prePreContent;

  /// Wraps a Dart value in a [YamlScalar].
  ///
  /// This scalar's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  YamlScalar.wrap(this.value, this.originalString, {sourceUrl})
      : style = ScalarStyle.ANY,
        prePreContent = '',
        super('', '') {
    _span = NullSpan(sourceUrl);
  }

  /// Users of the library should not use this constructor.
  YamlScalar.internal(this.value, ScalarEvent scalar)
      : style = scalar.style,
        originalString = scalar.rawContent,
        prePreContent = scalar.prePreContent,
        super(scalar.preContent, scalar.postContent) {
    _span = scalar.span;
  }

  /// Users of the library should not use this constructor.
  YamlScalar.internalWithSpan(this.value, SourceSpan span,
      {String originalString = '',
      this.style = ScalarStyle.PLAIN,
      String preContent = '',
      String postContent = ''})
      : prePreContent = '',
        originalString =
            originalString.isEmpty ? value.toString() : originalString,
        super(preContent, postContent) {
    _span = span;
  }

  @override
  String toString() => '$value';
}

/// Sets the source span of a [YamlNode].
///
/// This method is not exposed publicly.
void setSpan(YamlNode node, SourceSpan span) {
  node._span = span;
}
