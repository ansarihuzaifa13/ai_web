import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String?> pickFileName({String accept = '*'}) {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;

  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    completer.complete(file?.name);
  }).toJS;

  input.click();
  return completer.future;
}
