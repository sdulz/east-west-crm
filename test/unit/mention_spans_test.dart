import 'package:field_crm/features/activities/presentation/notes_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontWeight: FontWeight.w600);
  List<(String, bool)> parts(String text) => mentionSpans(text, [
    'Ram Thapa',
    'Ram',
    'Maya Shrestha',
  ], style).map((s) => ((s as TextSpan).text!, s.style == style)).toList();

  test('longest matching name wins and text around it is kept', () {
    expect(parts('ask @Ram Thapa today'), [
      ('ask ', false),
      ('@Ram Thapa', true),
      (' today', false),
    ]);
  });

  test('unknown mentions and bare @ stay plain', () {
    final p = parts('mail @nobody @ ok');
    expect(p.map((e) => e.$1).join(), 'mail @nobody @ ok');
    expect(p.any((e) => e.$2), isFalse);
  });
}
