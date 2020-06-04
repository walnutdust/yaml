import 'package:yaml/mod.dart';

void main() {
  var doc = loadYaml('''
? - Detroit Tigers
  - Chicago cubs
: 2002-08-03

? [ New York Yankees,
    Atlanta Braves ]
: [ 2001-07-02, 2001-08-12,
    2001-08-14 ]
''');
  doc[['Detroit Tigers', 'Chicago cubs']] = ['2001-07-23'];
  print(doc);
}
