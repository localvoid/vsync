// Copyright (c) 2014, the vsync project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vsync;

/// Virtual Text Node.
class Text extends Node {
  /// Text data
  String data;

  /// Create a new [Text]
  Text(Object key, this.data) : super(key);

  /// Run diff against [other] [Text]
  void sync(Text other, html.Text htmlText) {
    if (!identical(this, other) && data != other.data) {
      htmlText.data = other.data;
    }
  }

  /// Render [html.Text]
  html.Text render() {
    return new html.Text(data);
  }

  String toString() => '$data';
}
