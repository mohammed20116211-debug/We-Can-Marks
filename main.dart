import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calc.dart';

const maroon = Color(0xFFC41270), sky = Color(0xFF29BAEE), bg = Color(0xFFF5F6FA);

void main() => runApp(const App());

BoxDecoration cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [BoxShadow(color: maroon.withOpacity(.10), blurRadius: 24, offset: const Offset(0, 8))]);

Widget pill(String l, String v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: sky.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$l: ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        TextSpan(text: v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: sky)),
      ])),
    );

Widget scoreText(HistoryEntry e, double big, double small) => Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: e.score, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: maroon)),
        TextSpan(text: ' / ${e.total}', style: TextStyle(fontSize: small, fontWeight: FontWeight.w700, color: Colors.black45)),
      ])),
    );

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'We Can Marks',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: maroon, primary: maroon, secondary: sky),
          scaffoldBackgroundColor: bg,
          textTheme: GoogleFonts.tajawalTextTheme(),
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final t = TextEditingController(), n = TextEditingController(), w = TextEditingController();
  CalcResult? res;
  bool pressed = false;
  SharedPreferences? prefs;
  List<HistoryEntry> history = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      prefs = p;
      t.text = p.getString('v2_t') ?? '';
      n.text = p.getString('v2_n') ?? '';
      w.text = p.getString('v2_w') ?? '';
      history = decodeHistory(p.getString('hist'));
      setState(update);
    });
  }

  void update() {
    prefs?.setString('v2_t', t.text);
    prefs?.setString('v2_n', n.text);
    prefs?.setString('v2_w', w.text);
    final any = t.text.isNotEmpty || n.text.isNotEmpty || w.text.isNotEmpty;
    res = any ? calculate(t.text, n.text, w.text) : null;
  }

  void saveHistory(CalcResult r) {
    if (history.isNotEmpty) {
      final h = history.first;
      if (h.total == r.total && h.count == r.count && h.wrong == r.wrong) return;
    }
    history = addToHistory(history, HistoryEntry.from(r, DateTime.now().millisecondsSinceEpoch));
    prefs?.setString('hist', encodeHistory(history));
  }

  void confirmCalc() {
    FocusScope.of(context).unfocus();
    setState(() {
      pressed = true;
      update();
      final r = res;
      if (r != null && r.error == null) saveHistory(r);
    });
  }

  void clear() {
    t.clear(); n.clear(); w.clear();
    prefs?.remove('v2_t'); prefs?.remove('v2_n'); prefs?.remove('v2_w');
    setState(() { res = null; pressed = false; });
  }

  Future<void> openHistory() async {
    FocusScope.of(context).unfocus();
    final e = await Navigator.push<HistoryEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          entries: history,
          onClear: () { history = []; prefs?.remove('hist'); },
        ),
      ),
    );
    if (e != null) {
      setState(() {
        t.text = e.total;
        n.text = '${e.count}';
        w.text = '${e.wrong}';
        pressed = false;
        update();
      });
    }
  }

  Widget field(String label, String hint, TextEditingController c, {bool dec = false, bool last = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: dec),
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(dec ? r'[0-9٠-٩.,٫]' : r'[0-9٠-٩]'))],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            onChanged: (_) => setState(() { pressed = false; update(); }),
            onSubmitted: last ? (_) => confirmCalc() : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black38),
              filled: true, fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: sky, width: 2)),
            ),
          ),
        ]),
      );

  Widget stat(String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: sky.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: sky)),
            Text(l, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ]),
        ),
      );

  Widget historyButton() => Material(
        color: Colors.white.withOpacity(.22),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: openHistory,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text('السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = res;
    final showErr = r?.error != null && (pressed || (t.text.isNotEmpty && n.text.isNotEmpty && w.text.isNotEmpty));
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 70),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [maroon, sky], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Stack(children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Image.asset('assets/logo.png', height: 54),
                      ),
                      const SizedBox(height: 12),
                      const Text('We Can Marks', textDirection: TextDirection.ltr,
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      const Text('احسب درجات اختباراتك بسهولة ودقة', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ]),
                  ),
                  PositionedDirectional(top: 0, end: 0, child: historyButton()),
                ]),
              ),
              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(18), decoration: cardDeco(),
                      child: Column(children: [
                        field('الدرجة الكلية للاختبار', 'أدخل الدرجة', t, dec: true),
                        field('إجمالي عدد فقرات الاختبار', 'أدخل عدد الفقرات', n),
                        field('عدد الفقرات الخاطئة', 'أدخل عدد الأخطاء', w, last: true),
                        if (showErr || (pressed && r?.error != null))
                          Padding(padding: const EdgeInsets.only(bottom: 10),
                              child: Text(r!.error!, style: const TextStyle(color: maroon, fontWeight: FontWeight.w700))),
                        Row(children: [
                          Expanded(child: SizedBox(height: 58, child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: maroon,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            onPressed: confirmCalc,
                            child: const Text('احسب الدرجة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))))),
                          const SizedBox(width: 10),
                          SizedBox(height: 58, width: 100, child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: sky, side: const BorderSide(color: sky, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            onPressed: clear,
                            child: const Text('مسح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    if (r != null && r.error == null)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(18), decoration: cardDeco(),
                        child: Column(children: [
                          Directionality(textDirection: TextDirection.ltr,
                            child: Text.rich(TextSpan(children: [
                              TextSpan(text: r.score, style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w800, color: maroon)),
                              TextSpan(text: ' / ${r.total}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.black45)),
                            ]))),
                          const SizedBox(height: 14),
                          Row(children: [stat('${r.correct}', 'الفقرات الصحيحة'), const SizedBox(width: 10), stat('${r.wrong}', 'الفقرات الخاطئة')]),
                          const SizedBox(height: 10),
                          Row(children: [stat(r.perItem, 'قيمة الفقرة الواحدة')]),
                        ]),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final List<HistoryEntry> entries;
  final VoidCallback onClear;
  const HistoryPage({super.key, required this.entries, required this.onClear});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<HistoryEntry> items = List.of(widget.entries);

  Future<void> confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف سجل العمليات بالكامل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف', style: TextStyle(color: maroon, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok == true) {
      widget.onClear();
      setState(() => items = []);
    }
  }

  Widget row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
      );

  void showDetails(HistoryEntry e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          scoreText(e, 52, 26),
          Text(formatDate(e.date), textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.black45)),
          const SizedBox(height: 12),
          row('الدرجة الكلية للاختبار', e.total),
          row('إجمالي عدد الفقرات', '${e.count}'),
          row('عدد الفقرات الخاطئة', '${e.wrong}'),
          row('عدد الفقرات الصحيحة', '${e.correct}'),
          row('قيمة الفقرة الواحدة', e.perItem),
          row('الدرجة النهائية', e.score),
          const SizedBox(height: 14),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: maroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              onPressed: () { Navigator.pop(c); Navigator.pop(context, e); },
              child: const Text('تحميل في خانات الحساب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget entryCard(HistoryEntry e) => Container(
        decoration: cardDeco(),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDetails(e),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  scoreText(e, 36, 20),
                  Text(formatDate(e.date), textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  pill('الفقرات', '${e.count}'),
                  pill('الأخطاء', '${e.wrong}'),
                  pill('الصحيحة', '${e.correct}'),
                  pill('قيمة الفقرة', e.perItem),
                ]),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [maroon, sky], begin: Alignment.centerRight, end: Alignment.centerLeft),
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'مسح السجل', onPressed: confirmClear),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history, size: 64, color: sky),
                SizedBox(height: 12),
                Text('لا توجد عمليات محفوظة بعد', style: TextStyle(fontSize: 17, color: Colors.black54)),
              ]),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => entryCard(items[i]),
            ),
    );
  }
}
