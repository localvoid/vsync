// Copyright (c) 2014, the vsync project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vsync;

/// Virtual Dom Element
class Element extends Node {
  /// [Element] tag name
  final String tag;

  /// [Element] attributes
  Map<String, String> attributes;

  /// [Element] styles
  Map<String, String> styles;

  /// Element classes
  List<String> classes;

  /// Element children
  List<Node> children;

  /// Create a new [Element]
  Element(Object key, this.tag, [this.children = null, this.attributes = null, this.classes = null, this.styles = null]) : super(key);

  sync(Element other, html.Element htmlElement) {
    syncMap(attributes, other.attributes, htmlElement.attributes);
    syncStyle(styles, other.styles, htmlElement.style);
    syncSet(classes, other.classes, htmlElement.classes);
    syncChildren(children, other.children, htmlElement);
  }

  /// Render [Element] and return [html.Element]
  html.Element render() {
    var result = new html.Element.tag(tag);
    if (children != null) {
      for (final c in children) {
        result.append(c.render());
      }
    }
    if (attributes != null) {
      attributes.forEach((key, value) {
        result.setAttribute(key, value);
      });
    }
    if (styles != null) {
      styles.forEach((key, value) {
        result.style.setProperty(key, value);
      });
    }
    if (classes != null) {
      result.classes.addAll(classes);
    }

    return result;
  }

  String toString() => '<$tag key="$key">${children.join()}</$tag>';
}

void syncChildren(List<Node> a, List<Node> b, html.Element n) {
  if (a != null && a.isNotEmpty) {
    final aLength = a.length;

    if (b == null || b.isEmpty) {
      // when [b] is empty, it means that all childrens from list [a] were
      // removed
      var xNode = n.firstChild;
      for (final i in a) {
        final next = xNode.nextNode;
        xNode.remove();
        xNode = next;
        //i.detached();
      }
    } else {
      final bLength = b.length;

      if (aLength == 1 && bLength == 1) {
        // fast path when [a] and [b] have just 1 child
        //
        // if both lists have child with the same key, then just diff them,
        // otherwise return patch with [a] child removed and [b] child inserted
        final aNode = a.first;
        final bNode = b.first;

        if (aNode.key == bNode.key) {
          aNode.sync(bNode, n.firstChild);
        } else {
          // remove [a]
          n.firstChild.remove();
          //aNode.detached();

          // insert [b]
          n.append(bNode.render());
          //bNode.attached();
        }
      } else if (aLength == 1) {
        // fast path when [a] have 1 child
        final aNode = a.first;

        // [a] child position
        // if it is -1, then the child is removed
        var removed = true;
        var i = 0;
        final xNode = n.firstChild;
        for (; i < bLength; i++) {
          final bNode = b[i];
          if (aNode.key == bNode.key) {
            aNode.sync(bNode, xNode);
            removed = false;
            break;
          } else {
            n.insertBefore(bNode.render(), xNode);
            //bNode.attached();
          }
        }

        if (removed) {
          xNode.remove();
          //aNode.detached();
        } else {
          for (i++; i < bLength; i++) {
            final bNode = b[i];
            n.append(bNode.render());
            //bNode.attached();
          }
        }
      } else if (bLength == 1) {
        // fast path when [b] have 1 child
        final bNode = b.first;

        // [a] child position
        // if it is -1, then the child is inserted
        var inserted = true;
        var i = 0;
        var xNode = n.firstChild;
        for (; i < aLength; i++) {
          final aNode = a[i];
          if (aNode.key == bNode.key) {
            aNode.sync(bNode, xNode);
            inserted = false;
            break;
          } else {
            xNode.remove();
            //aNode.detached();
            xNode = n.firstChild;
          }
        }

        if (inserted) {
          final e = bNode.render();
          n.append(e);
          //bNode.attached();
        } else {
          xNode = xNode.nextNode;
          for (i++; i < aLength; i++) {
            final aNode = a[i];
            final next = xNode.nextNode;
            xNode.remove();
            //aNode.detached();
            xNode = next;
          }
        }
      } else {
        // both [a] and [b] have more than 1 child, so we should handle
        // more complex situations with inserting/removing and repositioning
        // childrens
        _syncChildren2(a, b, n);
      }
    }
  } else if (b != null && b.length > 0) {
    // all childrens from list [b] were inserted
    for (final bNode in b) {
      n.append(bNode.render());
      //bNode.attached();
    }
  }
}

/// Algorithm
/// - remove nodes
/// - move nodes
/// - insert nodes
void _syncChildren2(List<Node> a, List<Node> b, html.Element n) {
  final aLength = a.length;
  final bLength = b.length;

  final htmlNodes = new List<html.Node>();

  final unchangedSourcePositions = new List<int>();
  final unchangedTargetPositions = new List<int>();

  final insertedNodes = new List<Node>();
  final insertedPositions = new List<int>();

  // positions after nodes are removed
  final sources = new List<int>.filled(bLength, -1);

  var moved = false;

  var removeOffset = 0;

  // when both lists are small, the join operation is much faster with simple
  // MxN list search instead of hashmap join
  if (aLength * bLength <= 16) {
    var lastTarget = 0;
    var hNode = n.firstChild;

    // for each vnode in list a, find vnode with the same key in b
    // if it is found, then add their positions in unchangedLists
    // otherwise remove real html node from the childList
    for (var i = 0; i < aLength; i++) {
      final aNode = a[i];
      var removed = true;

      for (var j = 0; j < bLength; j++) {
        final bNode = b[j];
        if (aNode.key == bNode.key) {
          sources[j] = i - removeOffset;

          // set moved flag if nodes in the wrong order.
          if (lastTarget > j) {
            moved = true;
          } else {
            lastTarget = j;
          }

          unchangedSourcePositions.add(i);
          unchangedTargetPositions.add(j);

          removed = false;
          break;
        }
      }

      if (removed) {
        final next = hNode.nextNode;
        hNode.remove();
        //aNode.detached();
        hNode = next;
        removeOffset++;
      } else {
        htmlNodes.add(hNode);
        hNode = hNode.nextNode;
      }
    }

  } else {
    final keyIndex = new HashMap<Object, int>();
    var lastTarget = 0;

    // index nodes from list [b]
    for (var i = 0; i < bLength; i++) {
      final node = b[i];
      keyIndex[node.key] = i;
    }

    // index nodes from list [a] and check if they're removed
    var xNode = n.firstChild;
    for (var i = 0; i < aLength; i++) {
      final sourceNode = a[i];
      final targetIndex = keyIndex[sourceNode.key];
      if (targetIndex != null) {
        final targetNode = b[targetIndex];

        sources[targetIndex] = i - removeOffset;

        // set moved flag if nodes in the wrong order.
        if (lastTarget > targetIndex) {
          moved = true;
        } else {
          lastTarget = targetIndex;
        }

        unchangedSourcePositions.add(i);
        unchangedTargetPositions.add(targetIndex);

        htmlNodes.add(xNode);
        xNode = xNode.nextNode;
      } else {
        final next = xNode.nextNode;
        xNode.remove();
        //sourceNode.detached();
        xNode = next;
        removeOffset++;
      }
    }
  }

  var movedPositions;

  if (moved) {
    // create new list without removed/inserted nodes
    // and use source position ids instead of vnodes
    final c = new List<int>.filled(a.length - removeOffset, 0);

    // fill new lists and find all inserted/unchanged nodes
    var insertedOffset = 0;
    for (var i = 0; i < b.length; i++) {
      final node = b[i];
      if (sources[i] == -1) {
        insertedNodes.add(node);
        insertedPositions.add(i);
        insertedOffset++;
      } else {
        c[i - insertedOffset] = sources[i];
      }
    }

    final seq = _lis(c);

    final moveSources = new List<html.Node>();
    final moveTargets = new List<html.Node>();

    var i = c.length - 1;
    var j = seq.length - 1;

    while (i >= 0) {
      if (j < 0 || i != seq[j]) {
        html.Node t = null;
        if (i + 1 != c.length) {
          t = htmlNodes[c[i + 1]];
        }
        moveSources.add(htmlNodes[c[i]]);
        moveTargets.add(t);
      } else {
        j--;
      }
      i--;
    }

    for (var i = 0; i < moveSources.length; i++) {
      final s = moveSources[i];
      final t = moveTargets[i];
      n.insertBefore(s, t);
    }
  } else {
    for (var i = 0; i < b.length; i++) {
      final node = b[i];
      if (sources[i] == -1) {
        insertedNodes.add(node);
        insertedPositions.add(i);
      }
    }
  }

  // insert
  var j = 0;
  var hNode = n.firstChild;
  for (var i = 0; i < insertedNodes.length; i++) {
    final a = insertedNodes[i];
    final p = insertedPositions[i];
    while (p > j) {
      hNode = hNode.nextNode;
      j++;
    }
    n.insertBefore(a.render(), hNode);
    //a.attached();
    j++;
  }

  // recursive sync
  for (var i = 0; i < unchangedSourcePositions.length; i++) {
    final source = unchangedSourcePositions[i];
    final target = unchangedTargetPositions[i];
    final node = a[source];
    node.sync(b[target], htmlNodes[i]);
  }
}

/// Algorithm that finds longest increasing subsequence.
List<int> _lis(List<int> a) {
  List<int> p = new List<int>.from(a);
  List<int> result = new List<int>();

  result.add(0);

  for (var i = 0; i < a.length; i++) {
    if (a[result.last] < a[i]) {
      p[i] = result.last;
      result.add(i);
      continue;
    }

    var u = 0;
    var v = result.length - 1;
    while (u < v) {
      int c = (u + v) ~/ 2;

      if (a[result[c]] < a[i]) {
        u = c + 1;
      } else {
        v = c;
      }
    }

    if (a[i] < a[result[u]]) {
      if (u > 0) {
        p[i] = result[u - 1];
      }

      result[u] = i;
    }
  }
  var u = result.length;
  var v = result.last;

  while (u-- > 0) {
    result[u] = v;
    v = p[v];
  }

  return result;
}
