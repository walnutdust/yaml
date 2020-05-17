
**Note: This branch was created to explore YAML modification via AST manipulation.**

This branch has been set up for demonstration of YAML modification via AST manipulation.

YAML modification is achieved in the following ways:
1. `YamlNode`s from `package:yaml` are modified at parse-time to retain information about the 
whitespace and comments surrounding the node in `preContent` and `postContent` fields.
1. Modification is done by overriding `package:yaml`'s `YamlNode`s to allow for assignment operators
to work, and to remove unmodifiable mixins.
    * Removal is done while offloading the meta content to adjacent or parent nodes.
    * Addition requires the creation of new `YamlNodes`, and we have to determine
    the style of the `YamlNodes` to be created.
    * Note also that with any modification currently invalidates other `SourceSpans`
1. Dumping the final into YAML by carefully reconstructing them. 

To test this, clone the repository, and run the following commands:

```bash
$ dart example/gsoc.dart
```

Sample:
```dart
import 'package:yaml/spec.dart';

void main() {
  var spec = Spec.load(fileName: './example/samples/sample-pubspec.yaml');

  // Simple modification:
  spec['name'] = 'yaml-gsoc';

  // pub add
  spec.addDependency('gsoc', '>2.0.20');
  spec.addGitDependency('retry', 'git://github.com/google/dart-neats',
      path: 'retry', ref: 'master');

  // pub upgrade
  spec.upgrade('charcode', '^1.2.1');

  // pub remove
  spec.removeDependency('indent');

  // pub version
  spec.versionBumpMinor();

  print(spec.dump());
}
```

which should transform:
```yaml
name: yaml # comment
version: 2.2.1-dev # comment

description: A parser for YAML, a human-friendly data serialization standard
homepage: https://github.com/dart-lang/yaml

environment:
  sdk: '>=2.4.0 <3.0.0'

dependencies: # list of dependencies

  charcode: ^1.1.0 # charcode dependency
  collection: '>=1.1.0 <2.0.0'

  # comment

  string_scanner: '>=0.1.4 <2.0.0'
  source_span: '>=1.0.0 <2.0.0'
  indent: ^1.0.0+2 # indent dependency

# This is a list of dev dependencies
dev_dependencies:
  pedantic: ^1.0.0
  path: '>=1.2.0 <2.0.0'
  test: '>=0.12.0 <2.0.0'
```

into
```yaml
name: yaml-gsoc # comment
version: 2.3.1-dev # comment

description: A parser for YAML, a human-friendly data serialization standard
homepage: https://github.com/dart-lang/yaml

environment:
  sdk: '>=2.4.0 <3.0.0'

dependencies: # list of dependencies

  charcode: ^1.2.1 # charcode dependency
  collection: '>=1.1.0 <2.0.0'

  # comment

  string_scanner: '>=0.1.4 <2.0.0'
  source_span: '>=1.0.0 <2.0.0'
  gsoc: '>2.0.20'
  retry: 
    git:
      url: git://github.com/google/dart-neats
      ref: master
      path: retry

# This is a list of dev dependencies
dev_dependencies:
  pedantic: ^1.0.0
  path: '>=1.2.0 <2.0.0'
  test: '>=0.12.0 <2.0.0'

```

---

A parser for [YAML](http://www.yaml.org/).

[![Pub Package](https://img.shields.io/pub/v/yaml.svg)](https://pub.dev/packages/yaml)
[![Build Status](https://travis-ci.org/dart-lang/yaml.svg?branch=master)](https://travis-ci.org/dart-lang/yaml)


Use `loadYaml` to load a single document, or `loadYamlStream` to load a
stream of documents. For example:

```dart
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(doc['YAML']);
}
```

This library currently doesn't support dumping to YAML. You should use
`json.encode` from `dart:convert` instead:

```dart
import 'dart:convert';
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(json.encode(doc));
}
```
