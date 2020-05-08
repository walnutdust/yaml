import 'dart:io';

import 'package:yaml/yaml.dart';

void main() async {
  // testOneDirectory('./example/samples/');
  // testOneFile('./example/samples/test10.yaml');

  var sample = File('./example/samples/test10.yaml').readAsStringSync();
  var doc = loadYamlDocument(sample);
  //var docMap = doc.contents as YamlMap;

  // pub add
  //docMap['verb'] = 'hello';

  print(doc.dump());

  // docMap['verb'] = 'hi';
  // docMap['noun'] = 'he';
  // print('---');
  // print(doc.toPrettyString());
}

void testOneDirectory(String testDirectoryPath) {
  var testDirectory = Directory(testDirectoryPath);

  var testFiles = testDirectory.list(recursive: false, followLinks: false);
  var testSamples = testFiles.map((file) => file.path);

  testSamples.forEach((path) {
    testOneFile(path);
  });
}

void testOneFile(String path) {
  var sample = File(path).readAsStringSync();
  var docs = loadYamlDocuments(sample);
  docs.forEach((doc) {
    print(doc.dump());
  });
}
