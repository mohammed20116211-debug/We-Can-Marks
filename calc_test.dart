import 'package:flutter_test/flutter_test.dart';
import 'package:wecan_marks/calc.dart';

void main() {
  const cases = [
    ['10', '25', '5', '8'], ['30', '40', '10', '22.5'], ['20', '50', '7', '17.2'],
    ['10', '25', '0', '10'], ['10', '25', '25', '0'],
  ];
  for (final c in cases) {
    test('${c[0]}/${c[1]}/${c[2]}', () => expect(calculate(c[0], c[1], c[2]).score, c[3]));
  }
  test('validation', () {
    expect(calculate('', '5', '1').error, isNotNull);
    expect(calculate('0', '5', '1').error, isNotNull);
    expect(calculate('10', '5', '6').error, isNotNull);
    expect(calculate('10', '5', '-1').error, isNotNull);
    expect(calculate('10', 'a', '1').error, isNotNull);
  });

  test('history keeps 10, newest first', () {
    var l = <HistoryEntry>[];
    for (var i = 1; i <= 12; i++) {
      l = addToHistory(l, HistoryEntry.from(calculate('30', '40', '$i'), i));
    }
    expect(l.length, 10);
    expect(l.first.ts, 12);
    expect(l.last.ts, 3);
  });
  test('history json roundtrip', () {
    final e = HistoryEntry.from(calculate('30', '40', '10'), 5);
    final d = decodeHistory(encodeHistory([e]));
    expect(d.length, 1);
    expect(d.first.score, '22.5');
    expect(d.first.total, '30');
    expect(d.first.perItem, '0.75');
    expect(d.first.correct, 30);
    expect(decodeHistory('garbage'), isEmpty);
  });
}
