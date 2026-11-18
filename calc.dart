import 'dart:convert';

class CalcResult {
  final String? error;
  final int totalMilli, count, wrong, correct, hundredths;
  CalcResult.err(this.error)
      : totalMilli = 0, count = 0, wrong = 0, correct = 0, hundredths = 0;
  CalcResult(this.totalMilli, this.count, this.wrong)
      : error = null, correct = count - wrong,
        hundredths = (2 * totalMilli * (count - wrong) + 10 * count) ~/ (20 * count);
  String get score => _fmt(hundredths, 100, 2);
  String get total => _fmt(totalMilli, 1000, 3);
  String get perItem => _fmt((totalMilli * 1000 / count).round(), 1000000, 3);
}

String _fmt(int v, int scale, int dec) {
  var s = (v / scale).toStringAsFixed(dec);
  if (s.contains('.')) s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s;
}

String _digits(String s) {
  const a = '٠١٢٣٤٥٦٧٨٩', p = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final c in s.trim().split('')) {
    final i = a.indexOf(c), j = p.indexOf(c);
    b.write(i >= 0 ? '$i' : j >= 0 ? '$j' : (c == '٫' || c == '،' || c == ',') ? '.' : c);
  }
  return b.toString();
}

CalcResult calculate(String t, String n, String w) {
  t = _digits(t); n = _digits(n); w = _digits(w);
  if (t.isEmpty || n.isEmpty || w.isEmpty) return CalcResult.err('يرجى تعبئة جميع الخانات');
  final m = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$').firstMatch(t);
  if (m == null || !RegExp(r'^\d+$').hasMatch(n) || !RegExp(r'^\d+$').hasMatch(w)) {
    return CalcResult.err('يرجى إدخال أرقام صحيحة فقط (بدون إشارات سالبة أو حروف)');
  }
  final T = int.parse(m.group(1)!) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
  final N = int.parse(n), W = int.parse(w);
  if (T <= 0) return CalcResult.err('الدرجة الكلية يجب أن تكون أكبر من صفر');
  if (N <= 0) return CalcResult.err('عدد الفقرات يجب أن يكون أكبر من صفر');
  if (W > N) return CalcResult.err('عدد الفقرات الخاطئة لا يمكن أن يتجاوز إجمالي فقرات الاختبار');
  return CalcResult(T, N, W);
}

const maxHistory = 10;

class HistoryEntry {
  final String total, perItem, score;
  final int count, wrong, correct, ts;
  HistoryEntry({required this.total, required this.count, required this.wrong,
      required this.correct, required this.perItem, required this.score, required this.ts});
  factory HistoryEntry.from(CalcResult r, int ts) => HistoryEntry(
      total: r.total, count: r.count, wrong: r.wrong, correct: r.correct,
      perItem: r.perItem, score: r.score, ts: ts);
  Map<String, dynamic> toJson() => {
        't': total, 'n': count, 'w': wrong, 'c': correct, 'p': perItem, 's': score, 'd': ts,
      };
  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
      total: j['t'] as String, count: j['n'] as int, wrong: j['w'] as int,
      correct: j['c'] as int, perItem: j['p'] as String, score: j['s'] as String, ts: j['d'] as int);
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(ts);
}

List<HistoryEntry> addToHistory(List<HistoryEntry> list, HistoryEntry e) {
  final out = [e, ...list];
  return out.length > maxHistory ? out.sublist(0, maxHistory) : out;
}

String encodeHistory(List<HistoryEntry> l) => jsonEncode(l.map((e) => e.toJson()).toList());

List<HistoryEntry> decodeHistory(String? s) {
  if (s == null || s.isEmpty) return [];
  try {
    final l = (jsonDecode(s) as List)
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return l.length > maxHistory ? l.sublist(0, maxHistory) : l;
  } catch (_) {
    return [];
  }
}

String formatDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
}
