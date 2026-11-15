import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/audio_out.dart';
import 'ui/metronome_page.dart';
import 'ui/privacy.dart';
import 'ui/theme.dart';
import 'ui/tuner_page.dart';
import 'ui/widgets.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Celular fica em retrato. Tablet aceita qualquer orientação: no iPadOS 26 a
  // janela do app pode ter qualquer tamanho e formato, e o layout se ajusta.
  final display = binding.platformDispatcher.displays.firstOrNull;
  final isTablet =
      display != null &&
      (display.size / display.devicePixelRatio).shortestSide >= 600;
  if (!isTablet) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const AfinadorApp());
}

class AfinadorApp extends StatelessWidget {
  const AfinadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afinador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: bodyFont,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: bodyFont,
        brightness: Brightness.dark,
      ),
      // Em telas grandes, amplia tudo (inclusive menus e painéis).
      builder: (context, child) => _ScaleUp(child: child!),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AudioOut _audio = AudioOut();
  int _tab = 0;
  bool _inTune = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fora da tela, o microfone e o metrônomo param.
    final foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) setState(() => _foreground = foreground);
  }

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = dark ? Palette.dark : Palette.light;
    final p = (_inTune && _tab == 0) ? Palette.inTune : base;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark && !(_inTune && _tab == 0))
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: p.bg,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Numa janela muito estreita (multitarefa do iPad) fica só o diapasão.
                      LayoutBuilder(
                        builder: (context, constraints) => Row(
                          children: [
                            ForkIcon(color: p.brand),
                            if (constraints.maxWidth >= 300) ...[
                              const SizedBox(width: 8),
                              Text(
                                'afinador',
                                style: displayStyle(
                                  21,
                                  p.text,
                                ).copyWith(height: 1.2),
                              ),
                            ],
                            const Spacer(),
                            _tabs(p),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: IndexedStack(
                          index: _tab,
                          children: [
                            TunerPage(
                              palette: p,
                              active: _foreground && _tab == 0,
                              audio: _audio,
                              onTunedChanged: (tuned) =>
                                  setState(() => _inTune = tuned),
                            ),
                            MetronomePage(
                              palette: p,
                              active: _foreground && _tab == 1,
                              audio: _audio,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'um app ',
                              style: bodyStyle(11.5, p.muted),
                              children: [
                                TextSpan(
                                  text: 'Bancada',
                                  style: bodyStyle(
                                    11.5,
                                    p.text,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text('  ·  ', style: bodyStyle(11.5, p.muted)),
                          Semantics(
                            button: true,
                            child: GestureDetector(
                              onTap: () => showPrivacy(context, p),
                              child: Text(
                                'Privacidade',
                                style: bodyStyle(11.5, p.muted).copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(Palette p) {
    Widget tab(String label, int index) {
      final selected = _tab == index;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? p.text : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: bodyStyle(
                13,
                selected ? p.bg : p.muted,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [tab('Afinador', 0), tab('Metrônomo', 1)],
      ),
    );
  }
}

/// Em telas grandes (iPad, tablet) amplia o app inteiro por igual, até 1,6×,
/// para o mostrador não ficar pequeno no meio da tela. Envolve o Navigator,
/// então menus e painéis também crescem. Em celular não muda nada.
class _ScaleUp extends StatelessWidget {
  const _ScaleUp({required this.child});

  final Widget child;

  static const double _baseWidth = 500;
  static const double _baseHeight = 900;
  static const double _maxScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final scale = math
        .min(size.width / _baseWidth, size.height / _baseHeight)
        .clamp(1.0, _maxScale);
    if (scale == 1.0) return child;
    return FittedBox(
      child: SizedBox(
        width: size.width / scale,
        height: size.height / scale,
        child: MediaQuery(
          data: mq.copyWith(
            size: size / scale,
            padding: mq.padding / scale,
            viewPadding: mq.viewPadding / scale,
            viewInsets: mq.viewInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
