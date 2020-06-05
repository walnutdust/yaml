import 'package:yaml/mod.dart';

void main() {
  var doc = loadYaml('''
# a comment?
? # a comment?
  - Detroit Tigers
  - Chicago cubs
:
  - 2001-07-23

a: b
''');
  print(doc.value);
  doc.remove(['Detroit Tigers', 'Chicago cubs']);
  print(doc);
  doc.undo();
  print('===============');
  print(doc);
  doc.redo();
  print('===============');
  print(doc);

  print('=============');
  doc.undo();
  print('===============');
  print(doc);
  doc.redo();
  print('===============');
  print(doc);
}
