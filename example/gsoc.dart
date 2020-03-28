import 'dart:io';

import 'package:yaml/yaml.dart';

void main() async {
  // testOneDirectory('./example/samples/');
  testOneFile('./example/samples/test10.yaml');
}

void testOneDirectory(String testDirectoryPath) async {
  var testDirectory = Directory(testDirectoryPath);

  var testFiles = testDirectory.list(recursive: false, followLinks: false);
  var testSamples = testFiles.map((file) => file.path);

  await testSamples.forEach((path) {
    testOneFile(path);
  });
}

void testOneFile(String path) async {
  var sample = File(path).readAsStringSync();
  var docs = loadYamlDocuments(sample);
  docs.forEach((doc) {
    print(doc.toPrettyString());
  });
}
