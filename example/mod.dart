import 'dart:io';
import 'package:yaml/mod.dart';

void main() {
  var yaml = loadYaml(
      File('./example/samples/sample-pubspec.yaml').readAsStringSync());

  var yamlDeps = yaml['dependencies'];
  var yamlCollectionDep = yamlDeps['collection'];

  print(yamlCollectionDep); // >=1.1.0 <2.0.0

  yamlDeps['collection'] = '2.0.0';

  // yamlDeps and yaml will both be updated
  print(yamlDeps);
  print(yaml);

  yaml.remove('dependencies');

  print(yaml);
  print(yamlDeps);

  // ? Currently throws an error -> do we want this behavior?
  print(yamlCollectionDep);
}
