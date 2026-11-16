import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calc.dart';

const maroon = Color(0xFFC41270), sky = Color(0xFF29BAEE), bg = Color(0xFFF5F6FA);

void main() => runApp(const App());

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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      prefs = p;
      t.text = p.getString('t') ?? '';
      n.text = p.getString('n') ?? '';
      w.text = p.getString('w') ?? '';
      setState(update);
    });
  }

  void update() {
    prefs?.setString('t', t.text);
    prefs?.setString('n', n.text);
    prefs?.setString('w', w.text);
    final any = t.text.isNotEmpty || n.text.isNotEmpty || w.text.isNotEmpty;
    res = any ? calculate(t.text, n.text, w.text) : null;
  }

  void clear() {
    t.clear(); n.clear(); w.clear();
    prefs?.clear();
    setState(() { res = null; pressed = false; });
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
            decoration: InputDecoration(
              hintText: hint, filled: true, fillColor: bg,
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

  BoxDecoration card() => BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: maroon.withOpacity(.10), blurRadius: 24, offset: const Offset(0, 8))]);

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
              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(18), decoration: card(),
                      child: Column(children: [
                        field('الدرجة الكلية للاختبار', '30', t, dec: true),
                        field('إجمالي عدد فقرات الاختبار', '40', n),
                        field('عدد الفقرات الخاطئة', '10', w, last: true),
                        if (showErr || (pressed && r?.error != null))
                          Padding(padding: const EdgeInsets.only(bottom: 10),
                              child: Text(r!.error!, style: const TextStyle(color: maroon, fontWeight: FontWeight.w700))),
                        Row(children: [
                          Expanded(child: SizedBox(height: 58, child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: maroon,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            onPressed: () { FocusScope.of(context).unfocus(); setState(() { pressed = true; update(); }); },
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
                        width: double.infinity, padding: const EdgeInsets.all(18), decoration: card(),
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
