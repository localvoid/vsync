library vsync;

import 'dart:html' as html;
import 'dart:collection';

part 'package:vsync/src/set.dart';
part 'package:vsync/src/map.dart';
part 'package:vsync/src/style.dart';
part 'package:vsync/src/node.dart';
part 'package:vsync/src/text.dart';
part 'package:vsync/src/element.dart';

void sync(Node a, Node b, html.Node n) {
  a.sync(b, n);
}
