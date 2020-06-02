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

  // spec.upgrade('retry', '^3.0.0');

  // pub remove
  spec.removeDependency('indent');

  // pub version
  spec.versionBumpMinor();

  print(spec.dump());

  // Expected output:
  //
  // name: yaml-gsoc # comment
  // version: 2.3.1-dev # comment
  //
  // description: A parser for YAML, a human-friendly data serialization standard
  // homepage: https://github.com/dart-lang/yaml
  //
  // environment:
  //   sdk: '>=2.4.0 <3.0.0'
  //
  // dependencies: # list of dependencies
  //
  //   charcode: ^1.2.1 # charcode dependency
  //   collection: '>=1.1.0 <2.0.0'
  //
  //   # comment
  //
  //   string_scanner: '>=0.1.4 <2.0.0'
  //   source_span: '>=1.0.0 <2.0.0'
  //   gsoc: '>2.0.20'
  //   retry:
  //     git:
  //       url: git://github.com/google/dart-neats
  //       ref: master
  //       path: retry
  //
  // # This is a list of dev dependencies
  // dev_dependencies:
  //   pedantic: ^1.0.0
  //   path: '>=1.2.0 <2.0.0'
  //   test: '>=0.12.0 <2.0.0'
}
