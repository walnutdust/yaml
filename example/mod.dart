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

  spec.upgrade('retry', '^3.0.0');

  // pub remove
  spec.removeDependency('indent');

  // pub version
  spec.versionBumpMinor();

  print(spec.dump());
}
