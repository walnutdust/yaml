import 'package:yaml/spec.dart';

void main() {
  // testOneDirectory('./example/samples/');
  // testOneFile('./example/samples/test10.yaml');

  var spec = Spec.load(fileName: './example/samples/sample-pubspec.yaml');
  spec.versionBumpMinor();

  // Simple modification:
  spec['name'] = 'yaml-gsoc';

  // pub add
  // docMap['dependencies']['gsoc'] = '2.0.20';

  // pub upgrade
  spec['dependencies']['charcode'] = '^1.2.1';

  // pub remove
  (spec['dependencies'] as Map).remove('source_span');

  print(spec.dump());

  print('---');

  (spec['dependencies'] as Map).remove('indent');
  print(spec.dump());
}

void pubVersion() {}
