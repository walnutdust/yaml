import 'package:yaml/mod.dart';

void main() {
  var doc = loadYaml("[ 1 ,      2]");
  print(doc);
}
