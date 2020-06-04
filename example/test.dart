import 'package:yaml/mod.dart';

void main() {
  var doc = loadYaml('''
? - Detroit Tigers
  - Chicago cubs
:
  - 2001-07-23

''');
  doc[['Detroit Tigers', 'Chicago cubs']] = '2002-08-03';
  print(doc);
}
