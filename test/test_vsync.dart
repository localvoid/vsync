import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:vsync/vsync.dart' as v;

v.Element e(Object key, [Object c = const []]) {
  List children;
  if (c is String) {
    children = [new v.Text(0, c)];
  } else {
    children = c;
  }

  return new v.Element(key, 'div', children);
}

/// Generate list of VElements from simple integers.
///
/// For example, list `[0, 1, [2, [0, 1, 2]], 3]` will create
/// list with 4 VElements and the 2nd element will have key `2` and 3 childrens
/// of its own.
List<v.Element> gen(List items) {
  final result = [];
  for (var i in items) {
    if (i is List) {
      result.add(e(i[0], gen(i[1])));
    } else {
      result.add(e('text_$i', i.toString()));
    }
  }
  return result;
}

void checkSync(v.Element a, v.Element b) {
  final aHtmlNode = a.render();
  final bHtmlNode = b.render();

  a.sync(b, aHtmlNode);

  final aHtml = aHtmlNode.innerHtml;
  final bHtml = bHtmlNode.innerHtml;

  if (aHtml != bHtml) {
    throw new TestFailure('Expected: "$bHtml" Actual: "$aHtml"');
  }
}

void main() {
  useHtmlEnhancedConfiguration();

  group('Sync children', () {
    group('No modifications', () {
      test('No childrens', () {
        final a = e(0);
        final b = e(1);
        checkSync(a, b);
      });

      test('Same child', () {
        final a = e(0, gen([0]));
        final b = e(1, gen([0]));
        checkSync(a, b);
      });

      test('Same children', () {
        final a = e(0, gen([0, 1, 2]));
        final b = e(1, gen([0, 1, 2]));
        checkSync(a, b);
      });
    });

    group('Basic inserts', () {
      group('Into empty list', () {
        final a = e(0, []);

        final tests = [{
            'name': 'One item',
            'b': [1]
          }, {
            'name': 'Two items',
            'b': [4, 9]
          }, {
            'name': 'Five items',
            'b': [9, 3, 6, 1, 0]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;

          testFn(t['name'], () {
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });

      group('Into one element list', () {
        final a = e(0, gen([999]));

        final tests = [{
            'name': 'Prepend one item',
            'b': [1, 999]
          }, {
            'name': 'Append one item',
            'b': [999, 1]
          }, {
            'name': 'Prepend two items',
            'b': [4, 9, 999]
          }, {
            'name': 'Append two items',
            'b': [999, 4, 9]
          }, {
            'name': 'Prepend five items',
            'b': [9, 3, 6, 1, 0, 999]
          }, {
            'name': 'Append five items',
            'b': [999, 9, 3, 6, 1, 0]
          }, {
            'name': 'Prepend and append one item',
            'b': [0, 999, 1]
          }, {
            'name': 'Prepend and append two items',
            'b': [0, 3, 999, 1, 4]
          }, {
            'name': 'Prepend one and append three items',
            'b': [0, 999, 1, 4, 5]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;

          testFn(t['name'], () {
            final b = e(0, gen(t['b']));

            checkSync(a, b);
          });
        }
      });

      group('Into two elements list', () {
        final a = e(0, gen([998, 999]));

        final tests = [{
            'name': 'Prepend 1 item',
            'b': [1, 998, 999]
          }, {
            'name': 'Append 1 item',
            'b': [998, 999, 1]
          }, {
            'name': 'Insert betweem 1 item',
            'b': [998, 1, 999]
          }, {
            'name': 'Prepend 2 items',
            'b': [1, 2, 998, 999]
          }, {
            'name': 'Append 2 items',
            'b': [998, 999, 1, 2]
          }, {
            'name': 'Prepend and append 1 item',
            'b': [1, 998, 999, 2]
          }, {
            'name': 'Prepend, append and insert between 1 item',
            'b': [1, 998, 2, 999, 3]
          }, {
            'name': 'Prepend, append and insert between 2 items',
            'b': [1, 4, 998, 2, 5, 999, 3, 6]
          }, {
            'name': 'Prepend and insert between 1 item',
            'b': [1, 998, 2, 999]
          }, {
            'name': 'Append and insert between 1 item',
            'b': [998, 1, 999, 2]
          }, {
            'name': 'Prepend and insert between 2 items',
            'b': [1, 2, 998, 3, 4, 999]
          }, {
            'name': 'Append and insert between 2 items',
            'b': [998, 1, 2, 999, 3, 4]
          }, {
            'name': 'Prepend 10 items',
            'b': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 998, 999]
          }, {
            'name': 'Append 10 items',
            'b': [998, 999, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
          }, {
            'name': 'Prepend and append 5 items',
            'b': [0, 1, 2, 3, 4, 998, 999, 5, 6, 7, 8, 9]
          }, {
            'name': 'Prepend, append 3 items and insert between 4 items',
            'b': [0, 1, 2, 998, 3, 4, 5, 6, 999, 7, 8, 9]
          }, {
            'name': 'Prepend and insert between 5 items',
            'b': [0, 1, 2, 3, 4, 998, 5, 6, 7, 8, 9, 999]
          }, {
            'name': 'Append and insert between 5 items',
            'b': [998, 0, 1, 2, 3, 4, 999, 5, 6, 7, 8, 9]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;

          testFn(t['name'], () {
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });
    });

    group('Basic removes', () {
      group('1 item', () {
        final tests = [{
            'name': 'From 1-sized list',
            'a': [1],
            'b': []
          }, {
            'name': 'Front item from 2-sized list',
            'a': [1, 2],
            'b': [2]
          }, {
            'name': 'Back item from 2-sized list',
            'a': [1, 2],
            'b': [1]
          }, {
            'name': 'Front item from 3-sized list',
            'a': [1, 2, 3],
            'b': [2, 3]
          }, {
            'name': 'Back item from 3-sized list',
            'a': [1, 2, 3],
            'b': [1, 2]
          }, {
            'name': 'Middle item from 3-sized list',
            'a': [1, 2, 3],
            'b': [1, 3]
          }, {
            'name': 'Front item from 5-sized list',
            'a': [1, 2, 3, 4, 5],
            'b': [2, 3, 4, 5]
          }, {
            'name': 'Back item from 5-sized list',
            'a': [1, 2, 3, 4, 5],
            'b': [1, 2, 3, 4]
          }, {
            'name': 'Middle item from 5-sized list',
            'a': [1, 2, 3, 4, 5],
            'b': [1, 2, 4, 5]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;

          testFn(t['name'], () {
            final a = e(0, gen(t['a']));
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });

      group('2 items', () {
        final tests = [{
            'name': 'From 2-sized list',
            'a': [1, 2],
            'b': []
          }, {
            'name': 'Front items from 3-sized list',
            'a': [1, 2, 3],
            'b': [3]
          }, {
            'name': 'Back items from 3-sized list',
            'a': [1, 2, 3],
            'b': [1]
          }, {
            'name': 'Front items from 4-sized list',
            'a': [1, 2, 3, 4],
            'b': [3, 4]
          }, {
            'name': 'Back items from 4-sized list',
            'a': [1, 2, 3, 4],
            'b': [1, 2]
          }, {
            'name': 'Middle items from 4-sized list',
            'a': [1, 2, 3, 4],
            'b': [1, 4]
          }, {
            'name': 'Front and back items from 6-sized list',
            'a': [1, 2, 3, 4, 5, 6],
            'b': [2, 3, 4, 5]
          }, {
            'name': 'Front and middle items from 6-sized list',
            'a': [1, 2, 3, 4, 5, 6],
            'b': [2, 3, 5, 6]
          }, {
            'name': 'Back and middle items from 6-sized list',
            'a': [1, 2, 3, 4, 5, 6],
            'b': [1, 2, 3, 5]
          }, {
            'name': 'Front items from 10-sized list',
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [2, 3, 4, 5, 6, 7, 8, 9]
          }, {
            'name': 'Back items from 10-sized list',
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 3, 4, 5, 6, 7]
          }, {
            'name': 'Front and middle items from 10-sized list',
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [1, 2, 3, 4, 6, 7, 8, 9]
          }, {
            'name': 'Back and middle items from 10-sized list',
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 3, 4, 6, 7, 8]
          }, {
            'name': 'Middle items from 10-sized list',
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 4, 6, 7, 8, 9]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;

          testFn(t['name'], () {
            final a = e(0, gen(t['a']));
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });
    });

    group('Basic moves', () {
      final tests = [{
          'name': 'Swap 2 items in 2-items list',
          'a': [0, 1],
          'b': [1, 0]
        }, {
          'name': 'Reverse 4-items list',
          'a': [0, 1, 2, 3],
          'b': [3, 2, 1, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [1, 2, 3, 4, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [4, 0, 1, 2, 3]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [1, 0, 2, 3, 4]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [2, 0, 1, 3, 4]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 4, 2, 3]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 3, 4, 2]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 3, 2, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [2, 1, 0, 3, 4, 5, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 3, 4, 1, 2, 5, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 2, 3, 5, 6, 1, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 1, 5, 3, 2, 4, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          'b': [8, 1, 3, 4, 5, 6, 0, 7, 2, 9]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          'b': [9, 5, 0, 7, 1, 2, 3, 4, 6, 8]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert and Move', () {
      final tests = [{
          'a': [0, 1],
          'b': [2, 1, 0]
        }, {
          'a': [0, 1],
          'b': [1, 0, 2]
        }, {
          'a': [0, 1, 2],
          'b': [3, 0, 2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [0, 2, 1, 3]
        }, {
          'a': [0, 1, 2],
          'b': [0, 2, 3, 1]
        }, {
          'a': [0, 1, 2],
          'b': [1, 2, 3, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 2, 1, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 6, 2, 1, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 6, 2, 1, 0, 7]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Remove and Move', () {
      final tests = [{
          'a': [0, 1, 2],
          'b': [1, 0]
        }, {
          'a': [2, 0, 1],
          'b': [1, 0]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [7, 5, 4, 8, 3, 2, 1, 0]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 8, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [7, 5, 4, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 3, 2, 1, 0]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert and Remove', () {
      final tests = [{
          'a': [0],
          'b': [1]
        }, {
          'a': [0],
          'b': [1, 2]
        }, {
          'a': [0, 2],
          'b': [1]
        }, {
          'a': [0, 2],
          'b': [1, 2]
        }, {
          'a': [0, 2],
          'b': [2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [3, 4, 5]
        }, {
          'a': [0, 1, 2],
          'b': [2, 4, 5]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 8, 9, 10, 11]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 4, 8]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 3, 8]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert, Remove and Move', () {
      final tests = [{
          'a': [0, 1, 2],
          'b': [3, 2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [2, 1, 3]
        }, {
          'a': [1, 2, 0],
          'b': [2, 1, 3]
        }, {
          'a': [1, 2, 0],
          'b': [3, 2, 1]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 3, 2, 4, 7]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 2, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 3, 2, 4]
        }, {
          'a': [0, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 2, 4]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Modified children', () {
      final tests = [{
          'a': [[0, [0]]],
          'b': [0]
        }, {
          'a': [0, 1, [2, [0]]],
          'b': [2]
        }, {
          'a': [0],
          'b': [1, 2, [0, [0]]]
        }, {
          'a': [0, [1, [0, 1]], 2],
          'b': [3, 2, [1, [1, 0]]]
        }, {
          'a': [0, [1, [0, 1]], 2],
          'b': [2, [1, [1, 0]], 3]
        }, {
          'a': [[1, [0, 1]], [2, [0, 1]], 0],
          'b': [[2, [1, 0]], [1, [1, 0]], 3]
        }, {
          'a': [[1, [0, 1]], 2, 0],
          'b': [3, [2, [1, 0]], 1]
        }, {
          'a': [0, 1, 2, [3, [1, 0]], 4, 5],
          'b': [6, [1, [0, 1]], 3, 2, 4, 7]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, [1, [1]], 7, [3, [1]], [2, [1]], [4, [1]]]
        }, {
          'a': [0, 1, [2, [0]], 3, [4, [0]], 5],
          'b': [6, 7, 3, 2, 4]
        }, {
          'a': [0, [2, [0]], [3, [0]], [4, [0]], 5],
          'b': [6, 1, 7, 3, 2, 4]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });
  });
}
