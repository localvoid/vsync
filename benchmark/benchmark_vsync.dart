import 'dart:html' as html;
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vsync/vsync.dart' as v;

typedef v.Element GenerateTreeFunction(int rootElementsCount,
    int innerElementsCount);

v.Element generateTree(int rootElementsCount, int innerElementsCount) {
  final rootChildren = [];
  for (var i = 0; i < rootElementsCount; i++) {
    final innerChildren = [];

    //for (var j = 0; j < innerElementsCount; j++) {
    //  innerChildren.add(
    //      new v.Element(j, 'span', [new v.Text(j, j.toString())]));
    //}

    rootChildren.add(new v.Element(i, 'div', innerChildren));
  }

  return new v.Element('root', 'div', rootChildren);
}

v.Element generateTreeReversed(int rootElementsCount, int innerElementsCount) {
  final rootChildren = [];
  for (var i = 0; i < rootElementsCount; i++) {
    final innerChildren = [];

    //for (var j = innerElementsCount - 1; j >= 0; j--) {
    //  innerChildren.add(
    //      new v.Element(j, 'span', [new v.Text(j, j.toString())]));
    //}

    rootChildren.add(new v.Element(i, 'div', innerChildren));
  }

  return new v.Element('root', 'div', rootChildren.reversed.toList());
}

v.Element generateTreeSwapFirstLast(int rootElementsCount,
    int innerElementsCount) {
  final rootChildren = [];
  for (var i = 0; i < rootElementsCount; i++) {
    final innerChildren = [];

    //innerChildren.add(
    //    new v.Element(
    //        innerElementsCount - 1,
    //        'span',
    //        [new v.Text(innerElementsCount - 1, (innerElementsCount - 1).toString())]));

    //for (var j = 1; j < innerElementsCount - 1; j++) {
    //  innerChildren.add(
    //      new v.Element(j, 'span', [new v.Text(j, j.toString())]));
    //}

    //innerChildren.add(new v.Element(0, 'span', [new v.Text(0, 0.toString())]));

    rootChildren.add(new v.Element(i, 'div', innerChildren));
  }

  return new v.Element('root', 'div', rootChildren);
}

class DiffPatchBenchmark extends BenchmarkBase {
  final int rootElementsCount;
  final int innerElementsCount;
  final GenerateTreeFunction fn;
  final html.Element container;

  v.Element _root;
  v.Element _newRoot;
  html.Element _rootElement;

  DiffPatchBenchmark(String name, int rootElementsCount, int innerElementsCount,
      GenerateTreeFunction fn, html.Element container)
      : rootElementsCount = rootElementsCount,
        innerElementsCount = innerElementsCount,
        fn = fn,
        container = container,
        super('DiffPatch: $name');
  void run() {
    _root.sync(_newRoot, _rootElement);
  }

  void setup() {
    _root = generateTree(rootElementsCount, innerElementsCount);
    _rootElement = _root.render();
    container.append(_rootElement);
    _newRoot = fn(rootElementsCount, innerElementsCount);
  }

  void teardown() {
    _root = null;
    _rootElement.remove();
  }
}

void main() {
  final container = html.document.getElementById('container');

  final benchmarks = [
      new DiffPatchBenchmark(
          'reversed',
          1000, 2,
          generateTreeReversed,
          container),

      new DiffPatchBenchmark(
          'swap first-last',
          1000, 2,
          generateTreeSwapFirstLast,
          container),

      ];

  final e = html.document.getElementById('text');
  html.document.getElementById('button').onClick.listen((_) {
    e.text = 'started';
    for (final b in benchmarks) {
      b.report();
    }
    e.text = 'finished';
  });
}
