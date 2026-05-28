import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

enum AppMode { grid, custom, random, seq, debug, settings }
enum SequenceDirection { topToBottom, bottomToTop }
enum TimingMode { perShot, global }

// ─────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────
class MachineSettings {
  final String id;
  String name;
  double speed, turret, cowl, spin, freq;

  MachineSettings({
    required this.id,
    required this.name,
    required this.speed,
    required this.turret,
    required this.cowl,
    required this.spin,
    this.freq = 7,
  });

  @override
  bool operator ==(Object o) =>
      identical(this, o) || (o is MachineSettings && id == o.id);
  @override
  int get hashCode => id.hashCode;
}

// A saved sequence is a named list of MachineSettings references
class SavedSequence {
  final String id;
  String name;
  List<String> modeIds; // ordered list of mode ids
  SequenceDirection dir;
  TimingMode timing;
  double gFreq;

  SavedSequence({
    required this.id,
    required this.name,
    required this.modeIds,
    required this.dir,
    required this.timing,
    required this.gFreq,
  });
}

// ─────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Dark Minimal
// ─────────────────────────────────────────────────────────────────
class T {
  static const bg      = Color(0xFF0C0D10);
  static const surface = Color(0xFF141519);
  static const raised  = Color(0xFF1C1E25);
  static const border  = Color(0xFF252830);
  static const divider = Color(0xFF1E2027);

  // ── Court colors (new warm slate + clay scheme) ──────────────
  // Main court: deep blue-slate, like a premium hardcourt
  static const courtMain    = Color(0xFF1A2235);
  // Kitchen: warm terracotta/clay tint — immediately readable
  static const courtKitchen = Color.fromARGB(255, 35, 44, 69);
  // Court border/line tint
  static const courtLine    = Color(0xFF2E3850);
  // Net: warm gold stays, it pops against both zones
  static const net          = Color(0xFFD4A843);
  // Court divider line (centre service line, etc.)
  static const courtDiv     = Color(0xFF243048);

  static const cyan    = Color.fromARGB(255, 0, 178, 213);
  static const cyanDim = Color(0xFF0A1E24);
  static const green   = Color(0xFF00E68A);
  static const greenDim= Color(0xFF061A10);
  static const red     = Color(0xFFFF3B55);
  static const redDim  = Color(0xFF1F0810);
  static const amber   = Color(0xFFFFAA00);
  static const amberDim= Color(0xFF1E1400);
  static const violet  = Color(0xFFAA88FF);
  static const violetDim=Color(0xFF150E2A);

  static const textHi  = Color(0xFFEEEFF5);
  static const textMid = Color(0xFF6B7180);
  static const textLo  = Color(0xFF383C48);

  // Dots: on the blue court, bright cyan reads sharply
  static const dotOn      = Color.fromARGB(255, 8, 219, 46);
  // Random mode dots: warm coral/orange-red pops on clay kitchen too
  static const rDotOn     = Color(0xFFFF5C6E);
  // Off dot: slate-blue tint matches the court
  static const dotOff     = Color(0xFF2E3A52);
  // Kitchen off dot: slightly warmer to match kitchen zone
  static const kitchenDot = Color(0xFF2E3A52);

  static const shadow  = Color(0x55000000);

  // Warning color for deleted modes in sequences
  static const warn    = Color(0xFFFFAA00);
  static const warnDim = Color(0xFF1E1400);
}

TextStyle tx(double sz, Color c,
    {FontWeight w = FontWeight.w500, double ls = 0}) =>
    TextStyle(
        fontSize: sz,
        color: c,
        fontWeight: w,
        letterSpacing: ls,
        fontFamily: 'RobotoMono');

BoxDecoration _card({Color? border, Color? bg, Color? glow}) => BoxDecoration(
      color: bg ?? T.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: border ?? T.border, width: 1),
      boxShadow: glow != null
          ? [BoxShadow(color: glow.withOpacity(0.12), blurRadius: 16, spreadRadius: 0)]
          : [const BoxShadow(color: T.shadow, blurRadius: 6, offset: Offset(0, 2))],
    );

// ─────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  final Color accent;
  final Color accentBg;
  final double fontSize;
  final EdgeInsets padding;

  const _Pill(this.text, this.active, this.onTap, {
    this.accent   = T.cyan,
    this.accentBg = T.cyanDim,
    this.fontSize = 14,
    this.padding  = const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: padding,
          decoration: BoxDecoration(
            color: active ? accentBg : T.raised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: active ? accent.withOpacity(0.5) : T.border, width: 1),
          ),
          child: Text(text,
              style: tx(fontSize, active ? accent : T.textMid,
                  w: FontWeight.w700, ls: 0.5)),
        ),
      );
}

class _Sheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? accent;
  const _Sheet({required this.child, this.padding, this.accent});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: padding ?? const EdgeInsets.all(12),
        decoration: _card(
            border: accent?.withOpacity(0.2) ?? T.border,
            glow: accent),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: T.bg,
          fontFamily: 'RobotoMono',
          sliderTheme: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            thumbColor: Colors.white,
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            overlayColor: T.cyan.withOpacity(0.10),
            activeTrackColor: T.cyan,
            inactiveTrackColor: T.border,
          ),
        ),
        home: const MainPage(),
      );
}

// ─────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  // ── persistence ───────────────────────────────────────────────
  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('freq', freq);
    await p.setDouble('speedAdj', speedAdj);
    await p.setInt('numBalls', numBalls);
    await p.setString('speedSel', speedSel);
    await p.setString('patternSel', patternSel);
    await p.setDouble('startDelay', startDelay);
    await p.setBool('showRunning', showRunning);
    await p.setDouble('gFreq', gFreq);
    await p.setString('seqDir', seqDir.name);
    await p.setString('timing', timing.name);

    // Saved custom modes
    final modes = saved.where((s) => s.id != 'new_mode').toList();
    await p.setInt('savedCount', modes.length);
    for (int i = 0; i < modes.length; i++) {
      final s = modes[i];
      await p.setString('mode_${i}_id',     s.id);
      await p.setString('mode_${i}_name',   s.name);
      await p.setDouble('mode_${i}_speed',  s.speed);
      await p.setDouble('mode_${i}_turret', s.turret);
      await p.setDouble('mode_${i}_cowl',   s.cowl);
      await p.setDouble('mode_${i}_spin',   s.spin);
      await p.setDouble('mode_${i}_freq',   s.freq);
    }

    // Active (unsaved) seq list
    final seqIds = seqList.map((s) => s.id).toList();
    await p.setStringList('seqList', seqIds);

    // Current custom selection
    await p.setString('curCustomId', curCustom.id);

    // Saved sequences
    await p.setInt('savedSeqCount', savedSeqs.length);
    for (int i = 0; i < savedSeqs.length; i++) {
      final sq = savedSeqs[i];
      await p.setString('seq_${i}_id',      sq.id);
      await p.setString('seq_${i}_name',    sq.name);
      await p.setStringList('seq_${i}_modeIds', sq.modeIds);
      await p.setString('seq_${i}_dir',     sq.dir.name);
      await p.setString('seq_${i}_timing',  sq.timing.name);
      await p.setDouble('seq_${i}_gFreq',   sq.gFreq);
    }
    await p.setString('curSavedSeqId', curSavedSeq?.id ?? '');
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();

    freq       = p.getDouble('freq')       ?? 7;
    speedAdj   = p.getDouble('speedAdj')   ?? 1;
    numBalls   = p.getInt('numBalls')      ?? 10;
    speedSel   = p.getString('speedSel')   ?? 'Medium';
    patternSel = p.getString('patternSel') ?? '1-8,8-1';
    startDelay = p.getDouble('startDelay') ?? 0;
    showRunning= p.getBool('showRunning')  ?? false;
    gFreq      = p.getDouble('gFreq')      ?? 7;

    final seqDirStr = p.getString('seqDir') ?? 'topToBottom';
    seqDir = SequenceDirection.values.firstWhere(
        (e) => e.name == seqDirStr, orElse: () => SequenceDirection.topToBottom);

    final timingStr = p.getString('timing') ?? 'perShot';
    timing = TimingMode.values.firstWhere(
        (e) => e.name == timingStr, orElse: () => TimingMode.perShot);

    // Saved custom modes
    final count = p.getInt('savedCount') ?? 0;
    final loadedModes = <MachineSettings>[];
    for (int i = 0; i < count; i++) {
      final id = p.getString('mode_${i}_id');
      if (id == null) continue;
      loadedModes.add(MachineSettings(
        id:     id,
        name:   p.getString('mode_${i}_name')   ?? 'Mode $i',
        speed:  p.getDouble('mode_${i}_speed')  ?? 50,
        turret: p.getDouble('mode_${i}_turret') ?? 0,
        cowl:   p.getDouble('mode_${i}_cowl')   ?? 0,
        spin:   p.getDouble('mode_${i}_spin')   ?? 0,
        freq:   p.getDouble('mode_${i}_freq')   ?? 7,
      ));
    }
    saved = [_newTpl, ...loadedModes];

    // Active seq list
    final seqIds = p.getStringList('seqList') ?? [];
    seqList.clear();
    for (final id in seqIds) {
      final match = saved.firstWhere((s) => s.id == id,
          orElse: () => _newTpl);
      if (match.id != 'new_mode') seqList.add(match);
    }

    // Current custom selection
    final curId = p.getString('curCustomId') ?? 'new_mode';
    curCustom = saved.firstWhere((s) => s.id == curId,
        orElse: () => _newTpl);

    // Saved sequences
    final sqCount = p.getInt('savedSeqCount') ?? 0;
    savedSeqs.clear();
    for (int i = 0; i < sqCount; i++) {
      final id = p.getString('seq_${i}_id');
      if (id == null) continue;
      final dirStr = p.getString('seq_${i}_dir') ?? 'topToBottom';
      final timStr = p.getString('seq_${i}_timing') ?? 'perShot';
      savedSeqs.add(SavedSequence(
        id:      id,
        name:    p.getString('seq_${i}_name') ?? 'Sequence $i',
        modeIds: p.getStringList('seq_${i}_modeIds') ?? [],
        dir:     SequenceDirection.values.firstWhere(
            (e) => e.name == dirStr, orElse: () => SequenceDirection.topToBottom),
        timing:  TimingMode.values.firstWhere(
            (e) => e.name == timStr, orElse: () => TimingMode.perShot),
        gFreq:   p.getDouble('seq_${i}_gFreq') ?? 7,
      ));
    }

    // Restore current saved seq selection
    final curSqId = p.getString('curSavedSeqId') ?? '';
    if (curSqId.isNotEmpty) {
      curSavedSeq = savedSeqs.firstWhere((sq) => sq.id == curSqId,
          orElse: () => savedSeqs.isEmpty ? _nullSeq : savedSeqs.first);
    }
  }

  AppMode mode = AppMode.grid;

  bool connected = false;
  bool running   = false;

  bool clearGridFlash = false;
  bool clearRandFlash = false;
  bool testShotFlash  = false;
  bool speedUnlocked  = false;

  static const int kTopSize = 5;
  static const int kBotCols = 7;
  static const int kBotRows = 6;
  int topRow = 2, topCol = 2;
  final List<String> gridSel = [];
  final List<String> randSel = [];

  String patternSel = "1-8,8-1";
  String speedSel   = "Medium";
  double freq       = 7;
  double speedAdj   = 1;
  int    numBalls   = 10;

  bool?       _dragErase;
  final Set<String> _dragSeen = {};

  late MachineSettings _newTpl;
  late MachineSettings curCustom;
  late List<MachineSettings> saved;

  // Active sequence list (unsaved working state)
  final List<MachineSettings> seqList = [];
  SequenceDirection seqDir = SequenceDirection.topToBottom;
  TimingMode        timing = TimingMode.perShot;
  double            gFreq  = 7;

  // Saved sequences
  final List<SavedSequence> savedSeqs = [];
  SavedSequence? curSavedSeq;

  // Sentinel "no saved seq selected"
  final SavedSequence _nullSeq = SavedSequence(
    id: '__none__', name: 'Unsaved', modeIds: [],
    dir: SequenceDirection.topToBottom,
    timing: TimingMode.perShot, gFreq: 7,
  );

  double startDelay  = 0;
  bool   showRunning = false;

  int?    ballsLeft;
  double? delaySeconds;
  Timer?  _ballTimer;
  Timer?  _delayTicker;

  @override
  void initState() {
    super.initState();
    _newTpl = MachineSettings(
        id: 'new_mode', name: 'New mode',
        speed: 10, turret: 0, cowl: 0, spin: 0, freq: 7);
    curCustom = _newTpl;
    saved = [_newTpl];
    _loadPrefs().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _ballTimer?.cancel();
    _delayTicker?.cancel();
    super.dispose();
  }

  bool get _startAllowed =>
      mode != AppMode.debug && mode != AppMode.settings;

  void _stopAll() {
    _ballTimer?.cancel();
    _delayTicker?.cancel();
    _ballTimer = _delayTicker = null;
    if (running || delaySeconds != null) {
      setState(() { running = false; ballsLeft = null; delaySeconds = null; });
    }
  }

  void _startMachine() {
    if (!_startAllowed || running || delaySeconds != null) return;

    double ef = freq;
    if (mode == AppMode.custom) ef = curCustom.freq;
    if (mode == AppMode.seq && timing == TimingMode.global) ef = gFreq;

    final unlimited = numBalls == 25;

    void beginRunning() {
      setState(() {
        running      = true;
        delaySeconds = null;
        ballsLeft    = unlimited ? null : numBalls;
      });
      if (!unlimited && showRunning && numBalls > 0) {
        _ballTimer = Timer.periodic(
          Duration(milliseconds: (ef * 1000).round()),
          (t) => setState(() {
            if (ballsLeft != null && ballsLeft! > 0) {
              ballsLeft = ballsLeft! - 1;
              if (ballsLeft == 0) {
                t.cancel(); running = false; ballsLeft = null;
              }
            }
          }),
        );
      }
    }

    if (startDelay > 0) {
      setState(() => delaySeconds = startDelay);
      _delayTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
        setState(() {
          if (delaySeconds != null) {
            delaySeconds = delaySeconds! - 0.05;
            if (delaySeconds! <= 0) {
              delaySeconds = null;
              t.cancel();
              _delayTicker = null;
              beginRunning();
            }
          }
        });
      });
    } else {
      beginRunning();
    }
  }

  // ── Deleted-mode detection ─────────────────────────────────────
  // Returns true if any mode in seqList no longer exists in saved
  bool get _seqHasDeletedModes =>
      seqList.any((m) => !saved.any((s) => s.id == m.id));

  bool _modeIsDeleted(MachineSettings m) =>
      !saved.any((s) => s.id == m.id);

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (running && showRunning) {
      return Scaffold(
        backgroundColor: T.bg,
        body: SafeArea(child: _runningScreen()),
      );
    }

    return Scaffold(
      backgroundColor: T.bg,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          const SizedBox(height: 6),
          _modeRow(),
          const SizedBox(height: 2),
          Expanded(child: _modeContent()),
          _startStopBar(),
        ]),
      ),
    );
  }

  // ── running screen ────────────────────────────────────────────
  Widget _runningScreen() {
    final unlimited = numBalls == 25;
    return Column(children: [
      Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('BALLS LEFT', style: tx(10, T.textMid, w: FontWeight.w700, ls: 3)),
        const SizedBox(height: 28),
        unlimited
            ? Icon(Icons.all_inclusive, color: T.cyan, size: 90)
            : Text('${ballsLeft ?? numBalls}',
                style: tx(220, T.cyan, w: FontWeight.w700)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            color: T.greenDim,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: T.green.withOpacity(0.4)),
          ),
          child: Text('RUNNING', style: tx(10, T.green, w: FontWeight.w700, ls: 3)),
        ),
      ]))),
      _startStopBar(),
    ]);
  }

  // ── top bar ───────────────────────────────────────────────────
  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: Row(children: [
      _connBtn(),
      const Spacer(),
      _iconBtn(Icons.settings_outlined, mode == AppMode.settings, T.textMid, () {
        _stopAll(); setState(() => mode = AppMode.settings);
      }),
      const SizedBox(width: 8),
      _iconBtn(Icons.bug_report_outlined, mode == AppMode.debug, T.amber, () {
        _stopAll(); setState(() => mode = AppMode.debug);
      }),
    ]),
  );

  Widget _connBtn() => GestureDetector(
    onTap: () => setState(() => connected = !connected),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: connected ? T.greenDim : T.redDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: connected ? T.green.withOpacity(0.4) : T.red.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? T.green : T.red,
            boxShadow: [BoxShadow(
                color: (connected ? T.green : T.red).withOpacity(0.7),
                blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Text(connected ? 'CONNECTED' : 'DISCONNECTED',
            style: tx(11, connected ? T.green : T.red, w: FontWeight.w700, ls: 0.8)),
      ]),
    ),
  );

  Widget _iconBtn(IconData icon, bool active, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.10) : T.raised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? color.withOpacity(0.5) : T.border),
          ),
          child: Icon(icon, color: active ? color : T.textMid, size: 17),
        ),
      );

  // ── mode selector ─────────────────────────────────────────────
  Widget _modeRow() {
    Widget btn(String label, AppMode m) {
      final active = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () { _stopAll(); setState(() => mode = m); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 42,
            decoration: BoxDecoration(
              color: active ? T.cyanDim : T.raised,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: active ? T.cyan.withOpacity(0.5) : T.border, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: tx(17, active ? T.cyan : T.textMid,
                    w: FontWeight.w700, ls: 0.8)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        btn('GRID', AppMode.grid),
        btn('CUSTOM', AppMode.custom),
        btn('RANDOM', AppMode.random),
        btn('SEQ', AppMode.seq),
      ]),
    );
  }

  Widget _modeContent() {
    switch (mode) {
      case AppMode.grid:     return _gridMode();
      case AppMode.custom:   return _customMode();
      case AppMode.random:   return _randomMode();
      case AppMode.seq:      return _seqMode();
      case AppMode.debug:    return _debugMode();
      case AppMode.settings: return _settingsMode();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GRID MODE
  // ─────────────────────────────────────────────────────────────
  Widget _gridMode() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children: [
      const SizedBox(height: 10),
      _court(sel: gridSel, numbered: true),
      const SizedBox(height: 10),
      _patternRow(),
      const SizedBox(height: 8),
      _speedRow(),
      const SizedBox(height: 8),
      _sliderSheet('SPEED ADJ', '${speedAdj.toInt()}', T.green, T.cyanDim,
        Slider(min: -5, max: 5, divisions: 10, value: speedAdj,
          onChanged: (v) { _stopAll(); setState(() => speedAdj = v); }),
      ),
      _sliderSheet('FREQ', '${freq.toInt()}s', T.amber, T.amberDim,
        Slider(min: 3, max: 12, divisions: 9, value: freq,
          onChanged: (v) { _stopAll(); setState(() => freq = v); }),
      ),
      _ballsSheet(),
      const SizedBox(height: 20),
    ]),
  );

  // ─────────────────────────────────────────────────────────────
  // RANDOM MODE
  // ─────────────────────────────────────────────────────────────
  Widget _randomMode() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children: [
      const SizedBox(height: 10),
      _court(sel: randSel, numbered: false),
      const SizedBox(height: 8),
      Center(child: _Pill('CLEAR', clearRandFlash, () {
        _stopAll();
        setState(() { randSel.clear(); clearRandFlash = true; });
        Future.delayed(const Duration(milliseconds: 150),
            () => setState(() => clearRandFlash = false));
      }, accent: T.red, accentBg: T.redDim)),
      const SizedBox(height: 10),
      _speedRow(),
      const SizedBox(height: 8),
      _sliderSheet('SPEED ADJ', '${speedAdj.toInt()}', T.cyan, T.cyanDim,
        Slider(min: -5, max: 5, divisions: 10, value: speedAdj,
          onChanged: (v) { _stopAll(); setState(() => speedAdj = v); }),
      ),
      _sliderSheet('FREQ', '${freq.toInt()}s', T.amber, T.amberDim,
        Slider(min: 3, max: 12, divisions: 9, value: freq,
          onChanged: (v) { _stopAll(); setState(() => freq = v); }),
      ),
      _ballsSheet(),
      const SizedBox(height: 20),
    ]),
  );

  // ─────────────────────────────────────────────────────────────
  // CUSTOM MODE
  // ─────────────────────────────────────────────────────────────
  Widget _customMode() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Sheet(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: DropdownButton<MachineSettings>(
          isExpanded: true,
          dropdownColor: T.surface,
          underline: const SizedBox(),
          value: curCustom,
          style: tx(14, T.textHi),
          iconEnabledColor: T.textMid,
          items: saved.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.name, style: tx(14, T.textHi)),
          )).toList(),
          onChanged: (s) {
            if (s != null) { _stopAll(); setState(() => curCustom = s); }
          },
        ),
      ),
      _customSliders(),
      _ballsSheet(),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Pill('SAVE VALUES', true, _saveValues, accent: T.green, accentBg: T.greenDim),
        _Pill('SAVE NEW', true, _saveNew, accent: T.amber, accentBg: T.amberDim),
        _Pill('RENAME', true, _renameMode, accent: T.cyan, accentBg: T.cyanDim),
        _Pill('TEST SHOT', testShotFlash, () {
          setState(() => testShotFlash = true);
          Future.delayed(const Duration(milliseconds: 150),
              () => setState(() => testShotFlash = false));
        }, accent: T.violet, accentBg: T.violetDim),
        if (curCustom.id != 'new_mode')
          _Pill('DELETE', true, _deleteMode, accent: T.red, accentBg: T.redDim),
      ]),
    ]),
  );

  // ─────────────────────────────────────────────────────────────
  // SEQ MODE
  // ─────────────────────────────────────────────────────────────
  Widget _seqMode() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Saved sequence dropdown (mirrors Custom tab) ──────────
      _Sheet(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: DropdownButton<SavedSequence>(
          isExpanded: true,
          dropdownColor: T.surface,
          underline: const SizedBox(),
          value: curSavedSeq ?? _nullSeq,
          style: tx(14, T.textHi),
          iconEnabledColor: T.textMid,
          items: [
            DropdownMenuItem(
              value: _nullSeq,
              child: Text('Unsaved', style: tx(14, T.textMid)),
            ),
            ...savedSeqs.map((sq) => DropdownMenuItem(
              value: sq,
              child: Text(sq.name, style: tx(14, T.textHi)),
            )),
          ],
          onChanged: (sq) {
            if (sq == null) return;
            _stopAll();
            setState(() {
              if (sq.id == _nullSeq.id) {
                curSavedSeq = null;
              } else {
                curSavedSeq = sq;
                // Load the saved sequence into the working state
                _loadSavedSeq(sq);
              }
            });
          },
        ),
      ),

      // ── Save action buttons ────────────────────────────────────
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Pill('UPDATE', true, _updateSavedSeq,
            accent: T.green, accentBg: T.greenDim),
        _Pill('SAVE NEW', true, _saveNewSeq,
            accent: T.amber, accentBg: T.amberDim),
        _Pill('RENAME', true, _renameSavedSeq,
            accent: T.cyan, accentBg: T.cyanDim),
        if (curSavedSeq != null)
          _Pill('DELETE', true, _deleteSavedSeq,
              accent: T.red, accentBg: T.redDim),
      ]),
      const SizedBox(height: 14),

      // ── Deleted modes warning banner ───────────────────────────
      if (_seqHasDeletedModes)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: T.warnDim,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: T.warn.withOpacity(0.5)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: T.warn, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Some modes in this sequence were deleted. '
              'Remove them or replace before running.',
              style: tx(11, T.warn),
            )),
          ]),
        ),

      // ── Sequence list ─────────────────────────────────────────
      Row(children: [
        Text('SEQUENCE', style: tx(18, T.textMid, w: FontWeight.w700, ls: 1.5)),
        const Spacer(),
        _Pill('+ ADD', true, () { _stopAll(); _showAddSeqDialog(); },
            accent: T.cyan, accentBg: T.cyanDim,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
      ]),
      const SizedBox(height: 10),
      seqList.isEmpty
          ? _Sheet(child: Column(children: [
              const SizedBox(height: 14),
              Icon(Icons.playlist_add, color: T.textLo, size: 28),
              const SizedBox(height: 8),
              Text('No modes — tap + ADD', style: tx(15, T.textLo)),
              const SizedBox(height: 14),
            ]))
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: seqList.length,
              onReorder: (old, nw) {
                _stopAll();
                setState(() {
                  if (nw > old) nw--;
                  final it = seqList.removeAt(old);
                  seqList.insert(nw, it);
                });
              },
              itemBuilder: (ctx, i) =>
                  _seqItem(seqList[i], i, key: ValueKey('${seqList[i].id}_$i')),
            ),
      const SizedBox(height: 12),
      Text('ORDER', style: tx(14, T.textMid, w: FontWeight.w700, ls: 1.2)),
      const SizedBox(height: 8),
      _dirRow(),
      const SizedBox(height: 12),
      Text('TIMING', style: tx(14, T.textMid, w: FontWeight.w700, ls: 1.2)),
      const SizedBox(height: 8),
      _timingRow(),
      if (timing == TimingMode.global) ...[
        const SizedBox(height: 8),
        _sliderSheet('GLOBAL FREQ', '${gFreq.toInt()}s', T.amber, T.amberDim,
          Slider(min: 3, max: 12, divisions: 9, value: gFreq,
            onChanged: (v) { _stopAll(); setState(() => gFreq = v); }),
        ),
      ],
      const SizedBox(height: 8),
      _ballsSheet(),
    ]),
  );

  // Load a saved sequence into the active working state
  void _loadSavedSeq(SavedSequence sq) {
    seqList.clear();
    for (final id in sq.modeIds) {
      final match = saved.firstWhere((s) => s.id == id,
          orElse: () => _deletedPlaceholder(id));
      seqList.add(match);
    }
    seqDir = sq.dir;
    timing = sq.timing;
    gFreq  = sq.gFreq;
  }

  // Placeholder for a deleted mode — keeps it visible with a warning
  MachineSettings _deletedPlaceholder(String id) => MachineSettings(
    id: id, name: '[DELETED]',
    speed: 0, turret: 0, cowl: 0, spin: 0, freq: 7,
  );

  // ── Seq item (with deleted-mode highlight) ────────────────────
  Widget _seqItem(MachineSettings s, int i, {Key? key}) {
    final isDeleted = _modeIsDeleted(s);
    return ReorderableDragStartListener(
      key: key, index: i,
      child: _Sheet(
        accent: isDeleted ? T.red : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isDeleted ? T.redDim : T.cyanDim,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDeleted ? T.red.withOpacity(0.4) : T.cyan.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text('${i + 1}',
                style: tx(10, isDeleted ? T.red : T.cyan, w: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (isDeleted) ...[
                Icon(Icons.warning_amber_rounded, color: T.red, size: 13),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(s.name,
                  style: tx(16, isDeleted ? T.red : T.textHi,
                      w: FontWeight.w600))),
            ]),
            if (isDeleted)
              Text('Mode no longer exists — remove or replace',
                  style: tx(10, T.red.withOpacity(0.7)))
            else
              Text('SPD ${s.speed.toInt()}%  ·  F ${s.freq.toInt()}s  ·  T${s.turret.toInt()}°',
                  style: tx(12, T.textMid)),
          ])),
          // Replace button for deleted modes
          if (isDeleted) ...[
            GestureDetector(
              onTap: () => _showReplaceDeletedDialog(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: T.amberDim,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: T.amber.withOpacity(0.4)),
                ),
                child: Text('REPLACE', style: tx(9, T.amber, w: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 6),
          ],
          GestureDetector(
            onTap: () { _stopAll(); setState(() => seqList.removeAt(i)); },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: T.redDim,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: T.red.withOpacity(0.3)),
              ),
              child: Icon(Icons.close, color: T.red, size: 12),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.drag_handle, color: T.textLo, size: 18),
        ]),
      ),
    );
  }

  void _showReplaceDeletedDialog(int index) {
    final avail = saved.where((s) => s.id != 'new_mode').toList();
    if (avail.isEmpty) {
      _info('No Saved Modes', 'Go to Custom and save a mode first.');
      return;
    }
    showDialog(context: context, builder: (_) => _dlg(
      title: 'REPLACE WITH',
      body: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: avail.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(avail[i].name, style: tx(20, T.textHi)),
            subtitle: Text(
                'SPD ${avail[i].speed.toInt()}%  ·  FREQ ${avail[i].freq.toInt()}s',
                style: tx(13, T.textMid)),
            onTap: () {
              setState(() => seqList[index] = avail[i]);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      actions: [_dBtn('Cancel', T.textMid, () => Navigator.pop(context))],
    ));
  }

  void _showAddSeqDialog() {
    final avail = saved.where((s) => s.id != 'new_mode').toList();
    if (avail.isEmpty) {
      _info('No Saved Modes', 'Go to Custom and save a mode first.');
      return;
    }
    showDialog(context: context, builder: (_) => _dlg(
      title: 'ADD TO SEQUENCE',
      body: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: avail.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(avail[i].name, style: tx(20, T.textHi)),
            subtitle: Text(
                'SPD ${avail[i].speed.toInt()}%  ·  FREQ ${avail[i].freq.toInt()}s',
                style: tx(13, T.textMid)),
            onTap: () { setState(() => seqList.add(avail[i])); Navigator.pop(context); },
          ),
        ),
      ),
      actions: [_dBtn('Cancel', T.textMid, () => Navigator.pop(context))],
    ));
  }

  // ── Saved Sequence CRUD ────────────────────────────────────────
  void _saveNewSeq() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => _dlg(
      title: 'SAVE SEQUENCE AS',
      body: _textField(ctrl, T.amber),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Save', T.amber, () {
          final t = ctrl.text.trim();
          if (t.isEmpty) return;
          if (savedSeqs.any((sq) => sq.name.toLowerCase() == t.toLowerCase())) {
            Navigator.pop(context);
            _info('Name In Use', '"$t" already exists.');
            return;
          }
          setState(() {
            final nq = SavedSequence(
              id:      DateTime.now().millisecondsSinceEpoch.toString(),
              name:    t,
              modeIds: seqList.map((s) => s.id).toList(),
              dir:     seqDir,
              timing:  timing,
              gFreq:   gFreq,
            );
            savedSeqs.add(nq);
            curSavedSeq = nq;
          });
          _savePrefs();
          Navigator.pop(context);
        }),
      ],
    ));
  }

  void _updateSavedSeq() {
    if (curSavedSeq == null) {
      _info('No Sequence Selected', 'Use "Save New" to create a sequence first.');
      return;
    }
    setState(() {
      curSavedSeq!.modeIds = seqList.map((s) => s.id).toList();
      curSavedSeq!.dir     = seqDir;
      curSavedSeq!.timing  = timing;
      curSavedSeq!.gFreq   = gFreq;
    });
    _savePrefs();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('"${curSavedSeq!.name}" updated.', style: tx(12, Colors.white)),
      duration: const Duration(milliseconds: 1200),
      backgroundColor: T.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _renameSavedSeq() {
    if (curSavedSeq == null) {
      _info("Can't Rename", 'Select a saved sequence first.');
      return;
    }
    final ctrl = TextEditingController(text: curSavedSeq!.name);
    showDialog(context: context, builder: (_) => _dlg(
      title: 'RENAME SEQUENCE',
      body: _textField(ctrl, T.cyan),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Rename', T.cyan, () {
          final t = ctrl.text.trim();
          if (t.isEmpty) return;
          if (savedSeqs.any((sq) => sq.name.toLowerCase() == t.toLowerCase()
              && sq.id != curSavedSeq!.id)) {
            Navigator.pop(context);
            _info('Name In Use', '"$t" already exists.');
            return;
          }
          setState(() => curSavedSeq!.name = t);
          _savePrefs();
          Navigator.pop(context);
        }),
      ],
    ));
  }

  void _deleteSavedSeq() {
    if (curSavedSeq == null) return;
    showDialog(context: context, builder: (_) => _dlg(
      title: 'DELETE SEQUENCE',
      body: Text('Delete "${curSavedSeq!.name}"? This cannot be undone.',
          style: tx(12, T.textMid)),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Delete', T.red, () {
          setState(() {
            savedSeqs.removeWhere((sq) => sq.id == curSavedSeq!.id);
            curSavedSeq = null;
          });
          _savePrefs();
          Navigator.pop(context);
        }),
      ],
    ));
  }

  Widget _dirRow() {
    Widget btn(String label, SequenceDirection d) {
      final a = seqDir == d;
      return Expanded(child: GestureDetector(
        onTap: () { _stopAll(); setState(() => seqDir = d); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: a ? T.cyanDim : T.raised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: a ? T.cyan.withOpacity(0.5) : T.border),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: tx(14, a ? T.cyan : T.textMid, w: FontWeight.w700)),
        ),
      ));
    }
    return Row(children: [
      btn('1-8 | 8-1', SequenceDirection.topToBottom),
      btn('1-8 | 1-8', SequenceDirection.bottomToTop),
    ]);
  }

  Widget _timingRow() {
    Widget btn(String label, String sub, TimingMode m) {
      final a = timing == m;
      return Expanded(child: GestureDetector(
        onTap: () { _stopAll(); setState(() => timing = m); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: a ? T.amberDim : T.raised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: a ? T.amber.withOpacity(0.5) : T.border),
          ),
          child: Column(children: [
            Text(label, textAlign: TextAlign.center,
                style: tx(13, a ? T.amber : T.textMid, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, textAlign: TextAlign.center,
                style: tx(11, a ? T.amber.withOpacity(0.6) : T.textLo)),
          ]),
        ),
      ));
    }
    return Row(children: [
      btn('PER-SHOT', "Each mode's freq", TimingMode.perShot),
      btn('GLOBAL', 'One shared freq', TimingMode.global),
    ]);
  }

  // ─────────────────────────────────────────────────────────────
  // SETTINGS MODE
  // ─────────────────────────────────────────────────────────────
  Widget _settingsMode() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SETTINGS', style: tx(18, T.textHi, w: FontWeight.w700, ls: 1.5)),
      const SizedBox(height: 14),
      _sliderSheet('START DELAY',
          startDelay == 0 ? 'OFF' : '${startDelay.toStringAsFixed(1)}s',
          T.cyan, T.cyanDim,
        Slider(min: 0, max: 10, divisions: 20, value: startDelay,
          onChanged: (v) => setState(() => startDelay = v)),
      ),
      _Sheet(
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RUNNING DISPLAY', style: tx(13, T.textHi, w: FontWeight.w600)),
            Text('Show countdown while running', style: tx(11, T.textMid)),
          ])),
          GestureDetector(
            onTap: () => setState(() => showRunning = !showRunning),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 26,
              decoration: BoxDecoration(
                color: showRunning ? T.cyan : T.raised,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: showRunning ? T.cyan.withOpacity(0.6) : T.border),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: showRunning ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 4)]),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────
  // CUSTOM SLIDERS
  // ─────────────────────────────────────────────────────────────
  Widget _customSliders() => Column(children: [
    _sliderSheet('SPEED', '${curCustom.speed.toInt()}%', T.amber, T.amberDim,
      Slider(
        min: 10, max: 100, divisions: 18, value: curCustom.speed,
        activeColor: T.amber, inactiveColor: T.border,
        onChangeStart: (_) { if (curCustom.speed < 80) speedUnlocked = false; },
        onChanged: (v) {
          _stopAll();
          setState(() {
            final s = (v / 5).round() * 5.0;
            if (!speedUnlocked && s > 80 && curCustom.speed <= 80) {
              curCustom.speed = 80;
            } else { curCustom.speed = s; }
          });
        },
        onChangeEnd: (_) { if (curCustom.speed == 80) speedUnlocked = true; },
      ),
    ),
    _sliderSheet('TURRET', '${curCustom.turret.toInt()}°', T.cyan, T.cyanDim,
      Slider(min: -20, max: 20, divisions: 40, value: curCustom.turret,
        activeColor: T.cyan, inactiveColor: T.border,
        onChanged: (v) { _stopAll(); setState(() => curCustom.turret = v); }),
    ),
    _sliderSheet('COWL', '${curCustom.cowl.toInt()}°', T.violet, T.violetDim,
      Slider(min: 0, max: 20, divisions: 20, value: curCustom.cowl,
        activeColor: T.violet, inactiveColor: T.border,
        onChanged: (v) { _stopAll(); setState(() => curCustom.cowl = v); }),
    ),
    _sliderSheet('SPIN', '${curCustom.spin.toInt()}', T.green, T.greenDim,
      Slider(min: -10, max: 10, divisions: 20, value: curCustom.spin,
        activeColor: T.green, inactiveColor: T.border,
        onChanged: (v) { _stopAll(); setState(() => curCustom.spin = v); }),
    ),
    _sliderSheet('FREQ', '${curCustom.freq.toInt()}s', T.amber, T.amberDim,
      Slider(min: 3, max: 12, divisions: 9, value: curCustom.freq,
        activeColor: T.amber, inactiveColor: T.border,
        onChanged: (v) { _stopAll(); setState(() => curCustom.freq = v); }),
    ),
  ]);

  Widget _sliderSheet(String label, String val,
      Color accent, Color accentBg, Widget slider) {
    return _Sheet(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      accent: accent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: tx(13, T.textMid, w: FontWeight.w700, ls: 0.8)),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(val, style: tx(15, accent, w: FontWeight.w700)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: Colors.white,
            overlayColor: accent.withOpacity(0.10),
            inactiveTrackColor: T.border,
          ),
          child: slider,
        ),
      ]),
    );
  }

  Widget _ballsSheet() {
    final label = numBalls == 25 ? 'UNTIL STOP' : '$numBalls';
    return _sliderSheet('# OF BALLS', label, T.cyan, T.cyanDim,
      Slider(min: 0, max: 25, divisions: 25,
        value: numBalls.toDouble(),
        activeColor: T.cyan, inactiveColor: T.border,
        onChanged: (v) { _stopAll(); setState(() => numBalls = v.round()); }),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE / RENAME / DELETE (Custom mode)
  // ─────────────────────────────────────────────────────────────
  void _saveNew() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => _dlg(
      title: 'SAVE AS NEW MODE',
      body: _textField(ctrl, T.cyan),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Save', T.cyan, () {
          final t = ctrl.text.trim();
          if (t.isEmpty) return;
          if (saved.any((s) => s.name.toLowerCase() == t.toLowerCase())) {
            Navigator.pop(context);
            _info('Name In Use', '"$t" already exists.');
            return;
          }
          setState(() {
            final np = MachineSettings(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: t, speed: curCustom.speed, turret: curCustom.turret,
              cowl: curCustom.cowl, spin: curCustom.spin, freq: curCustom.freq,
            );
            saved.add(np);
            curCustom = np;
          });
          _savePrefs();
          Navigator.pop(context);
        }),
      ],
    ));
  }

  void _saveValues() {
    if (curCustom.id == 'new_mode') {
      _info('No Mode Selected', 'Use "Save New" to create a mode first.');
      return;
    }
    setState(() {});
    _savePrefs();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('"${curCustom.name}" saved.', style: tx(12, Colors.white)),
      duration: const Duration(milliseconds: 1200),
      backgroundColor: T.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _renameMode() {
    if (curCustom.id == 'new_mode') {
      _info("Can't Rename", 'Use "Save New" to create a mode first.');
      return;
    }
    final ctrl = TextEditingController(text: curCustom.name);
    showDialog(context: context, builder: (_) => _dlg(
      title: 'RENAME MODE',
      body: _textField(ctrl, T.cyan),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Rename', T.cyan, () {
          final t = ctrl.text.trim();
          if (t.isEmpty) return;
          if (saved.any((s) => s.name.toLowerCase() == t.toLowerCase())) {
            Navigator.pop(context);
            _info('Name In Use', '"$t" already exists.');
            return;
          }
          setState(() => curCustom.name = t);
          Navigator.pop(context);
        }),
      ],
    ));
  }

  void _deleteMode() {
    if (curCustom.id == 'new_mode') return;

    // Check if this mode is used in any saved sequence
    final affectedSeqs = savedSeqs
        .where((sq) => sq.modeIds.contains(curCustom.id))
        .map((sq) => sq.name)
        .toList();

    // Also check the active seqList
    final inActiveSeq = seqList.any((s) => s.id == curCustom.id);

    final hasRefs = affectedSeqs.isNotEmpty || inActiveSeq;

    showDialog(context: context, builder: (_) => _dlg(
      title: 'DELETE MODE',
      body: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Delete "${curCustom.name}"? This cannot be undone.',
            style: tx(12, T.textMid)),
        if (hasRefs) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: T.warnDim,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: T.warn.withOpacity(0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded, color: T.warn, size: 14),
                const SizedBox(width: 6),
                Text('Used in sequences', style: tx(11, T.warn, w: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              if (inActiveSeq)
                Text('· Current sequence (unsaved)', style: tx(11, T.warn)),
              ...affectedSeqs.map((n) => Text('· $n', style: tx(11, T.warn))),
              const SizedBox(height: 4),
              Text('Those entries will be marked as [DELETED].',
                  style: tx(10, T.warn.withOpacity(0.7))),
            ]),
          ),
        ],
      ]),
      actions: [
        _dBtn('Cancel', T.textMid, () => Navigator.pop(context)),
        _dBtn('Delete', T.red, () {
          setState(() {
            seqList.removeWhere((s) => s.id == curCustom.id);
            saved.removeWhere((s) => s.id == curCustom.id);
            // Note: savedSeqs keep the id in modeIds — they'll show as [DELETED]
            curCustom = _newTpl;
          });
          _savePrefs();
          Navigator.pop(context);
        }),
      ],
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // DIALOG HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _dlg({required String title, required Widget body,
      required List<Widget> actions}) =>
    AlertDialog(
      backgroundColor: T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(title, style: tx(13, T.textHi, w: FontWeight.w700, ls: 1)),
      content: body,
      actions: actions,
    );

  Widget _textField(TextEditingController ctrl, Color accent) => TextField(
    controller: ctrl,
    style: tx(13, T.textHi),
    cursorColor: accent,
    decoration: InputDecoration(
      labelStyle: tx(12, T.textMid),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: T.border)),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2)),
    ),
  );

  Widget _dBtn(String t, Color c, VoidCallback f) =>
      TextButton(onPressed: f,
          child: Text(t, style: tx(12, c, w: FontWeight.w700, ls: 0.5)));

  void _info(String title, String body) => showDialog(
    context: context,
    builder: (_) => _dlg(
      title: title, body: Text(body, style: tx(12, T.textMid)),
      actions: [_dBtn('OK', T.cyan, () => Navigator.pop(context))],
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // SHARED CONTROLS
  // ─────────────────────────────────────────────────────────────
  Widget _patternRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _Pill('CLEAR', clearGridFlash, () {
        _stopAll();
        setState(() { gridSel.clear(); clearGridFlash = true; });
        Future.delayed(const Duration(milliseconds: 150),
            () => setState(() => clearGridFlash = false));
      }, accent: T.red, accentBg: T.redDim),
      const SizedBox(width: 8),
      _Pill('1-8|8-1', patternSel == '1-8|8-1',
          () { _stopAll(); setState(() => patternSel = '1-8|8-1'); }),
      const SizedBox(width: 8),
      _Pill('1-8|1-8', patternSel == '1-8|1-8',
          () { _stopAll(); setState(() => patternSel = '1-8|1-8'); }),
    ],
  );

  Widget _speedRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('SPEED:', style: tx(15, T.textMid, w: FontWeight.w700, ls: 0.8)),
      const SizedBox(width: 10),
      _Pill('SLOW', speedSel == 'Slow',
          () { _stopAll(); setState(() => speedSel = 'Slow'); }),
      const SizedBox(width: 6),
      _Pill('MED', speedSel == 'Medium',
          () { _stopAll(); setState(() => speedSel = 'Medium'); }),
      const SizedBox(width: 6),
      _Pill('FAST', speedSel == 'Fast',
          () { _stopAll(); setState(() => speedSel = 'Fast'); }),
    ],
  );

  // ─────────────────────────────────────────────────────────────
  // START / STOP BAR
  // ─────────────────────────────────────────────────────────────
  Widget _startStopBar() {
    final canStart = _startAllowed;
    final inDelay  = delaySeconds != null;

    String startLabel;
    Color  startFg;
    Color  startBg;
    Color  startBorder;

    if (!canStart) {
      startLabel = 'START';
      startFg    = T.textLo;
      startBg    = T.raised;
      startBorder= T.border;
    } else if (inDelay) {
      final d = delaySeconds!.clamp(0.0, double.infinity);
      startLabel = d.toStringAsFixed(2);
      startFg    = T.amber;
      startBg    = T.amberDim;
      startBorder= T.amber;
    } else if (running) {
      startLabel = 'START';
      startFg    = T.green;
      startBg    = T.greenDim;
      startBorder= T.green;
    } else {
      startLabel = 'START';
      startFg    = T.cyan;
      startBg    = T.cyanDim;
      startBorder= T.cyan;
    }

    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border)),
        boxShadow: const [BoxShadow(color: T.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: canStart && !inDelay ? _startMachine : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: startBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: startBorder.withOpacity(0.6), width: 1.5),
              boxShadow: (canStart && (running || inDelay))
                  ? [BoxShadow(color: startBorder.withOpacity(0.2), blurRadius: 16)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(startLabel,
                style: tx(inDelay ? 22 : 26, startFg,
                    w: FontWeight.w700, ls: inDelay ? 0 : 3.0)),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () { _stopAll(); setState(() {}); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: (!running && !inDelay) ? T.redDim : T.raised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: (!running && !inDelay)
                      ? T.red.withOpacity(0.6) : T.border,
                  width: 1.5),
              boxShadow: (!running && !inDelay)
                  ? [BoxShadow(color: T.red.withOpacity(0.15), blurRadius: 16)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text('STOP',
                style: tx(26,
                    (!running && !inDelay) ? T.red : T.textLo,
                    w: FontWeight.w700, ls: 3.0)),
          ),
        )),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COURT — new warm slate + clay scheme
  // ─────────────────────────────────────────────────────────────
  Widget _court({required List<String> sel, required bool numbered}) {
    const pad = 20.0, hit = 58.0;
    final w = 320.0 - 40;
    final h = w * (44 / 20);

    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: T.courtMain,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: T.courtLine, width: 2),
        boxShadow: [
          const BoxShadow(color: T.shadow, blurRadius: 12),
          // Subtle inner glow to separate court from app bg
          BoxShadow(
              color: T.courtLine.withOpacity(0.08),
              blurRadius: 0, spreadRadius: -1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: LayoutBuilder(builder: (ctx, c) {
          final kitchen = c.maxHeight * (7 / 44) - 20;
          return Column(children: [
            Expanded(child: Stack(clipBehavior: Clip.none, children: [
              // Kitchen strip (top half)
              Positioned(bottom: 0, left: 0, right: 0, height: kitchen,
                  child: Container(
                      decoration: BoxDecoration(
                        color: T.courtKitchen,
                        border: Border(
                            top: BorderSide(color: T.courtLine.withOpacity(0.6), width: 1)),
                      ))),
              // Vertical centre line (top half)
              // Positioned(
              //   left: c.maxWidth / 2 - 0.5, top: 0, bottom: 0, width: 1,
              //   child: Container(color: T.courtLine.withOpacity(0.35)),
              // ),
              _topGrid(c, pad, hit, kitchen),
            ])),
            // Net bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  T.net,
                  T.net,
                  T.net,
                  T.net,
                ]),
                boxShadow: [
                  BoxShadow(color: T.net.withOpacity(0.25), blurRadius: 8),
                ],
              ),
            ),
            Expanded(child: Stack(children: [
              // Kitchen strip (bottom half)
              Positioned(top: 0, left: 0, right: 0, height: kitchen,
                  child: Container(
                      decoration: BoxDecoration(
                        color: T.courtKitchen,
                        border: Border(
                            bottom: BorderSide(color: T.courtLine.withOpacity(0.6), width: 1)),
                      ))),
              // Vertical centre line (bottom half)
              // Positioned(
              //   left: c.maxWidth / 2 - 0.5, top: kitchen, bottom: 0, width: 1,
              //   child: Container(color: T.courtLine.withOpacity(0.35)),
              // ),
              _botGrid(c, pad, hit, kitchen, sel, numbered),
            ])),
          ]);
        }),
      ),
    );
  }

  // ── top grid — machine (crosshair icon) ──────────────────────
  Widget _topGrid(BoxConstraints c, double pad, double hit, double kitchen) {
    final uH = c.maxHeight / 2 - kitchen - pad * 2;
    final uW = c.maxWidth - pad * 2;
    return Stack(clipBehavior: Clip.none, children: [
      for (int r = 0; r < kTopSize; r++)
        for (int col = 0; col < kTopSize; col++)
          Positioned(
            left: pad + col * (uW / (kTopSize - 1)) - hit / 2,
            top:  pad + r   * (uH / (kTopSize - 1)) - hit / 2,
            child: GestureDetector(
              onTap: () { _stopAll(); setState(() { topRow = r; topCol = col; }); },
              child: Container(
                width: hit, height: hit,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: T.dotOff,
                    border: Border.all(
                        color: T.courtLine.withOpacity(0.5), width: 1),
                  ),
                ),
              ),
            ),
          ),
      // Machine position: crosshair / target reticle
      Positioned(
        left: pad + topCol * (uW / (kTopSize - 1)) - 16,
        top:  pad + topRow * (uH / (kTopSize - 1)) - 16,
        child: _CrosshairIcon(size: 32, color: T.cyan),
      ),
    ]);
  }

  // ── bottom grid ──────────────────────────────────────────────
  Widget _botGrid(BoxConstraints c, double pad, double hit, double kitchen,
      List<String> sel, bool numbered) {
    final uH = c.maxHeight / 2 - kitchen - pad * 2;
    final uW = c.maxWidth - pad * 2;

    String? keyAt(Offset local) {
      final col = ((local.dx - pad) / (uW / (kBotCols - 1))).round();
      if (local.dy >= 0 && local.dy < kitchen) {
        if (col >= 0 && col < kBotCols) return '$col,0';
        return null;
      }
      final row = ((local.dy - pad - kitchen) / (uH / (kBotRows - 2))).round() + 1;
      if (row < 1 || row >= kBotRows || col < 0 || col >= kBotCols) return null;
      return '$col,$row';
    }

    void touch(String key) {
      if (_dragSeen.contains(key)) return;
      _dragSeen.add(key);
      setState(() {
        if (_dragErase == true) sel.remove(key);
        else if (!sel.contains(key)) sel.add(key);
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        _stopAll(); _dragSeen.clear();
        final k = keyAt(d.localPosition);
        if (k != null) { _dragErase = sel.contains(k); touch(k); }
        else _dragErase = false;
      },
      onPanUpdate: (d) {
        if (_dragErase == null) return;
        final k = keyAt(d.localPosition);
        if (k != null) touch(k);
      },
      onPanEnd: (_) { _dragSeen.clear(); _dragErase = null; },
      child: Stack(children: [
        for (int col = 0; col < kBotCols; col++)
          _botCell(0, col, uW, uH, pad, hit, kitchen, sel, numbered, inKitchen: true),
        for (int r = 1; r < kBotRows; r++)
          for (int col = 0; col < kBotCols; col++)
            _botCell(r, col, uW, uH, pad, hit, kitchen, sel, numbered, inKitchen: false),
      ]),
    );
  }

  Widget _botCell(int r, int col, double w, double h,
      double pad, double hit, double kitchen,
      List<String> sel, bool numbered, {required bool inKitchen}) {
    final key   = '$col,$r';
    final idx   = sel.indexOf(key);
    final on    = idx >= 0;
    final color = mode == AppMode.random ? T.rDotOn : T.dotOn;

    // Kitchen dots use a slightly warmer off color
    final offColor = inKitchen ? T.dotOff : T.dotOff;

    final double top = inKitchen
        ? kitchen / 1.5
        : pad + kitchen + (r - 1) * (h / (kBotRows - 2));

    return Positioned(
      left: pad + col * (w / (kBotCols - 1)) - hit / 2,
      top:  top - hit / 2,
      child: GestureDetector(
        onTap: () {
          _stopAll();
          setState(() { if (sel.contains(key)) sel.remove(key); else sel.add(key); });
        },
        child: Container(
          width: hit, height: hit, alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? color : offColor,
              border: Border.all(
                color: on
                    ? color.withOpacity(0.5)
                    : (inKitchen
                        ? const Color.fromARGB(255, 33, 43, 63).withOpacity(0.5)
                        : T.courtLine.withOpacity(0.4)),
                width: 1,
              ),
              boxShadow: on
                  ? [BoxShadow(color: color.withOpacity(0.50), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: (numbered && on)
                ? Text('${idx + 1}',
                    style: tx(14, Colors.black.withOpacity(0.85), w: FontWeight.w800))
                : null,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DEBUG MODE
  // ─────────────────────────────────────────────────────────────
  Widget _debugMode() {
    Widget kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$k  ', style: tx(11, T.textMid, w: FontWeight.w700, ls: 0.2)),
        Expanded(child: Text(v, style: tx(11, T.textHi))),
      ]),
    );

    Widget section(String title, Color accent, List<Widget> rows) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: _card(border: accent.withOpacity(0.25), glow: accent),
        child: IntrinsicHeight(child: Row(children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(10, accent, w: FontWeight.w700, ls: 1.5)),
              const SizedBox(height: 6),
              ...rows,
            ]),
          )),
        ])),
      );

    final eff = _effectiveSeq();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        section('GRID', T.cyan, [
          kv('Top pos', 'col $topCol  row $topRow'),
          kv('Dots', gridSel.isEmpty ? 'None' : gridSel.join(' → ')),
          kv('Pattern', patternSel),
          kv('Speed', speedSel),
          kv('Speed adj', '${speedAdj.toInt()}'),
          kv('Freq', '${freq.toInt()}s'),
          kv('Balls', numBalls == 25 ? 'Until Stop' : '$numBalls'),
        ]),
        section('RANDOM', T.red, [
          kv('Dots', randSel.isEmpty ? 'None' : randSel.join(', ')),
          kv('Speed', speedSel),
          kv('Speed adj', '${speedAdj.toInt()}'),
          kv('Freq', '${freq.toInt()}s'),
          kv('Balls', numBalls == 25 ? 'Until Stop' : '$numBalls'),
        ]),
        section('CUSTOM', T.amber, [
          kv('Mode', curCustom.name),
          kv('Speed', '${curCustom.speed.toInt()}%'),
          kv('Turret', '${curCustom.turret.toInt()}°'),
          kv('Cowl', '${curCustom.cowl.toInt()}°'),
          kv('Spin', '${curCustom.spin.toInt()}'),
          kv('Freq', '${curCustom.freq.toInt()}s'),
          kv('Balls', numBalls == 25 ? 'Until Stop' : '$numBalls'),
        ]),
        section('SEQ', T.violet, [
          kv('Saved seq', curSavedSeq?.name ?? 'Unsaved'),
          kv('Direction', _dirLabel(seqDir)),
          kv('Timing', timing == TimingMode.perShot
              ? 'Per-shot' : 'Global ${gFreq.toInt()}s'),
          kv('Order', seqList.isEmpty ? 'Empty'
              : seqList.map((s) => s.name).join(' → ')),
          kv('Playback', eff.isEmpty ? 'Empty'
              : eff.map((s) => s.name).join(' → ')),
          kv('Balls', numBalls == 25 ? 'Until Stop' : '$numBalls'),
          kv('Saved seqs', savedSeqs.isEmpty ? 'None'
              : savedSeqs.map((sq) => sq.name).join(', ')),
          if (eff.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...eff.asMap().entries.map((e) {
              final f = timing == TimingMode.global
                  ? gFreq.toInt() : e.value.freq.toInt();
              return kv('  ${e.key + 1}. ${e.value.name}', 'freq ${f}s');
            }),
          ],
        ]),
        section('SETTINGS', T.green, [
          kv('Start delay', startDelay == 0 ? 'Off' : '${startDelay.toStringAsFixed(1)}s'),
          kv('Running display', showRunning ? 'On' : 'Off'),
        ]),
      ]),
    );
  }

  List<MachineSettings> _effectiveSeq() {
    if (seqList.isEmpty) return [];
    return seqDir == SequenceDirection.topToBottom
        ? List.from(seqList) : List.from(seqList.reversed);
  }

  String _dirLabel(SequenceDirection d) => d == SequenceDirection.topToBottom
      ? '1 → 8 | 8 → 1' : 'Bottom → Top';
}

// ─────────────────────────────────────────────────────────────────
// CROSSHAIR ICON — custom painted target reticle
// ─────────────────────────────────────────────────────────────────
class _CrosshairIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _CrosshairIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _CrosshairPainter(color),
      );
}

class _CrosshairPainter extends CustomPainter {
  final Color color;
  _CrosshairPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final gap = r * 0.28;
    final lineLen = r * 0.42;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), r * 0.88, paint);
    canvas.drawCircle(Offset(cx, cy), r * 0.22, paint);
    canvas.drawCircle(Offset(cx, cy), r * 0.08, dotPaint);

    canvas.drawLine(Offset(cx, cy - gap), Offset(cx, cy - gap - lineLen), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + lineLen), paint);
    canvas.drawLine(Offset(cx - gap, cy), Offset(cx - gap - lineLen, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + lineLen, cy), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color;
}