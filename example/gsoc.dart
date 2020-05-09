import 'package:yaml/spec.dart';

void main() {
  var spec = Spec.load(fileName: './example/samples/sample-pubspec.yaml');

  // Simple modification:
  spec['name'] = 'yaml-gsoc';

  // pub add
  spec.addDependency('gsoc', '2.0.20');

  // pub upgrade
  spec.upgrade('charcode', '^1.2.1');

  // pub remove
  spec.removeDependency('indent');

  // pub version
  spec.versionBumpMinor();

  print(spec.dump());
}

void pubVersion() {}
