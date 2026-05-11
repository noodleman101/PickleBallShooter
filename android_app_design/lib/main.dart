import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

enum AppMode { grid, custom, random, seq, debug }
enum SequenceDirection { topToBottom, bottomToTop }
enum TimingMode { perShot, global }

class Settings {
  final String id;
  String name;
  double speed;
  double turret;
  double cowl;
  double spin;
  double freq;

  Settings({
    required this.id,
    required this.name,
    required this.speed,
    required this.turret,
    required this.cowl,
    required this.spin,
    this.freq = 7,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainControllerPage(),
      theme: ThemeData.dark(),
    );
  }
}

class MainControllerPage extends StatefulWidget {
  @override
  _MainControllerPageState createState() => _MainControllerPageState();
}

class _MainControllerPageState extends State<MainControllerPage> {
  // ── MODE ──────────────────────────────────────────────────────────
  AppMode currentMode = AppMode.grid;

  // ── COLORS ────────────────────────────────────────────────────────
  final Color gridSelectedColor     = const Color.fromARGB(255, 55, 215, 37);
  final Color gridUnselectedColor   = Colors.white70;
  final Color randomSelectedColor   = const Color.fromARGB(255, 229, 25, 25);
  final Color randomUnselectedColor = Colors.white54;

  // ── STATUS ────────────────────────────────────────────────────────
  bool isConnected = false;
  bool isRunning   = false;

  // ── FLASH STATES ──────────────────────────────────────────────────
  bool clearGridActive   = false;
  bool randomClearActive = false;
  bool testShotActive    = false;

  bool speedUnlocked = false;

  // ── GRID MODE ─────────────────────────────────────────────────────
  static const int topGridSize           = 5;
  static const int bottomGridSizeColumns = 7;
  static const int bottomGridSizeRows    = 5;
  int topRow = 2, topCol = 2;
  List<String> bottomSelectionOrder = [];

  // ── RANDOM MODE ───────────────────────────────────────────────────
  List<String> randomBottomSelection = [];

  // ── SHARED GRID SETTINGS (Grid & Random) ─────────────────────────
  String pattern      = "1-8,8-1";
  String speedPattern = "Medium";
  double freq             = 7;
  double speedAdjustment  = 1;

  // ── DRAG SELECT (improved) ────────────────────────────────────────
  // _dragErasing is determined by the FIRST dot touched, not drag direction.
  // null = not dragging, true = erasing stroke, false = adding stroke
  bool?       _dragErasing;
  Set<String> _dragVisited = {};

  // ── CUSTOM MODE ───────────────────────────────────────────────────
  final Settings _newTemplate = Settings(
    id: "new_mode", name: "New mode",
    speed: 10, turret: 0, cowl: 0, spin: 0, freq: 7,
  );
  late Settings       currentCustom;
  late List<Settings> savedSettings; // shared with Seq tab

  // ── SEQUENCE (Seq tab) ────────────────────────────────────────────
  List<Settings>    sequenceList      = [];
  SequenceDirection sequenceDirection = SequenceDirection.topToBottom;
  TimingMode        timingMode        = TimingMode.perShot;
  double            globalFreq        = 7;

  @override
  void initState() {
    super.initState();
    savedSettings = [_newTemplate];
    currentCustom = _newTemplate;
  }

  // ════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(30),
        child: AppBar(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          title: const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(children: [_buildConnectionButton()]),
              ),
              SizedBox(height: 12),
              _buildModeSelector(),
              SizedBox(height: 8),
              Expanded(child: _buildModeContent()),
              _buildStartStop(),
            ],
          ),
          Positioned(top: 3, right: 14, child: _buildDebugButton()),
        ],
      ),
    );
  }

  // ── CONNECTION ────────────────────────────────────────────────────
  Widget _buildConnectionButton() {
    return GestureDetector(
      onTap: () => setState(() => isConnected = !isConnected),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isConnected ? "Connected" : "Disconnected",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // ── DEBUG BUTTON ──────────────────────────────────────────────────
  Widget _buildDebugButton() {
    return GestureDetector(
      onTap: () => setState(() => currentMode = AppMode.debug),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: currentMode == AppMode.debug
              ? const Color.fromARGB(255, 219, 144, 15)
              : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("Debug",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // MODE SELECTOR  Grid | Custom | Random | Seq
  // ════════════════════════════════════════════════════════════════════
  Widget _buildModeSelector() {
    Widget btn(String text, AppMode mode) {
      final active = currentMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => currentMode = mode),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            height: 46,
            decoration: BoxDecoration(
              color: active ? Colors.blueAccent : Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(text,
                style: TextStyle(
                  fontSize: 22,
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          btn("Grid",   AppMode.grid),
          btn("Custom", AppMode.custom),
          btn("Random", AppMode.random),
          btn("Seq",    AppMode.seq),
        ],
      ),
    );
  }

  // ── ROUTER ────────────────────────────────────────────────────────
  Widget _buildModeContent() {
    switch (currentMode) {
      case AppMode.grid:   return _buildGridMode();
      case AppMode.custom: return _buildCustomMode();
      case AppMode.random: return _buildRandomMode();
      case AppMode.seq:    return _buildSeqMode();
      case AppMode.debug:  return _buildDebugMode();
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // GRID MODE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildGridMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          _buildCourt(bottomGrid: bottomSelectionOrder, numbered: true),
          SizedBox(height: 16),
          _buildPatternButtons(),
          SizedBox(height: 14),
          _buildSpeedRow(),
          SizedBox(height: 14),
          _buildSpeedAdjustmentSlider(),
          _buildFreqSlider(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // RANDOM MODE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildRandomMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          _buildCourt(bottomGrid: randomBottomSelection, numbered: false),
          SizedBox(height: 12),
          _selectButton("Clear", randomClearActive, () {
            setState(() { randomBottomSelection.clear(); randomClearActive = true; });
            Future.delayed(Duration(milliseconds: 150),
                () => setState(() => randomClearActive = false));
          }, activeColor: Colors.redAccent),
          SizedBox(height: 20),
          _buildSpeedRow(),
          SizedBox(height: 14),
          _buildSpeedAdjustmentSlider(),
          _buildFreqSlider(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // CUSTOM MODE — edit & save individual modes only
  // ════════════════════════════════════════════════════════════════════
  Widget _buildCustomMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mode:",
                style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            DropdownButton<Settings>(
              dropdownColor: Colors.grey[850],
              value: currentCustom,
              items: savedSettings.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name, style: TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (s) { if (s != null) setState(() => currentCustom = s); },
            ),
            SizedBox(height: 12),
            _buildCustomSliders(),
            SizedBox(height: 14),
            Row(
              children: [
                _selectButton("Save", true, _saveCustomSettings,
                    activeColor: Colors.orangeAccent),
                SizedBox(width: 12),
                _selectButton("Test Shot", testShotActive, () {
                  setState(() => testShotActive = true);
                  Future.delayed(Duration(milliseconds: 150),
                      () => setState(() => testShotActive = false));
                }, activeColor: Colors.pinkAccent),
              ],
            ),
            SizedBox(height: 20),
            // Hint nudge to Seq tab
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SEQ TAB — sequence builder, reads from savedSettings
  // ════════════════════════════════════════════════════════════════════
  Widget _buildSeqMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sequence",
                    style: TextStyle(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _showAddToSequenceDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text("Add",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // ── Reorderable list ───────────────────────────────────
            sequenceList.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.list_alt, color: Colors.white24, size: 36),
                        SizedBox(height: 8),
                        Text("No modes yet — tap Add",
                            style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: sequenceList.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = sequenceList.removeAt(oldIndex);
                        sequenceList.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (ctx, i) {
                      final s = sequenceList[i];
                      return _buildSeqItem(s, i, key: ValueKey('${s.id}_$i'));
                    },
                  ),

            SizedBox(height: 20),

            // ── Direction ──────────────────────────────────────────
            Text("Direction",
                style: TextStyle(
                    fontSize: 15, color: Colors.white70, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildDirectionSelector(),

            SizedBox(height: 18),

            // ── Timing ─────────────────────────────────────────────
            Text("Timing",
                style: TextStyle(
                    fontSize: 15, color: Colors.white70, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildTimingModeSelector(),
            if (timingMode == TimingMode.global) ...[
              SizedBox(height: 10),
              _buildGlobalFreqSlider(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Seq list item ─────────────────────────────────────────────────
  Widget _buildSeqItem(Settings s, int index, {Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text("${index + 1}",
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        title: Text(s.name,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          "Spd ${s.speed.toInt()}%  ·  Freq ${s.freq.toInt()}s  ·  T${s.turret.toInt()}°",
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => sequenceList.removeAt(index)),
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.close, color: Colors.redAccent, size: 17),
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.drag_handle, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Add-to-sequence dialog ────────────────────────────────────────
  void _showAddToSequenceDialog() {
    final available = savedSettings.where((s) => s.id != "new_mode").toList();
    if (available.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text("No Saved Modes", style: TextStyle(color: Colors.white)),
          content: Text("Go to Custom and save a mode first.",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text("Add to Sequence",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (ctx, i) {
              final s = available[i];
              return ListTile(
                title: Text(s.name, style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    "Spd ${s.speed.toInt()}%  ·  Freq ${s.freq.toInt()}s",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  setState(() => sequenceList.add(s));
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ── Direction selector ────────────────────────────────────────────
  Widget _buildDirectionSelector() {
    Widget btn(String label, String sub, SequenceDirection dir, IconData icon) {
      final active = sequenceDirection == dir;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => sequenceDirection = dir),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: active ? Colors.blueAccent : Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active ? Colors.blueAccent : Colors.white24, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(icon, color: active ? Colors.white : Colors.white54, size: 20),
                SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn("Top→Bot",   "1,2,3…",    SequenceDirection.topToBottom, Icons.arrow_downward),
        btn("Bot→Top",   "…3,2,1",    SequenceDirection.bottomToTop, Icons.arrow_upward),
      ],
    );
  }

  // ── Timing mode selector ──────────────────────────────────────────
  Widget _buildTimingModeSelector() {
    Widget btn(String label, String desc, TimingMode mode) {
      final active = timingMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => timingMode = mode),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: active ? Colors.orangeAccent.withOpacity(0.85) : Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active ? Colors.orangeAccent : Colors.white24, width: 1.5),
            ),
            child: Column(
              children: [
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 3),
                Text(desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: active ? Colors.white60 : Colors.white30,
                        fontSize: 10)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn("Per-Shot", "Each mode's own freq", TimingMode.perShot),
        btn("Global",   "One shared freq",      TimingMode.global),
      ],
    );
  }

  // ── Global freq slider ────────────────────────────────────────────
  Widget _buildGlobalFreqSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Global Freq (s): ${globalFreq.toInt()}",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        Slider(
          activeColor: Colors.orangeAccent, inactiveColor: Colors.grey,
          min: 3, max: 12, divisions: 9,
          value: globalFreq,
          onChanged: (v) => setState(() => globalFreq = v),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // CUSTOM SLIDERS
  // ════════════════════════════════════════════════════════════════════
  Widget _buildCustomSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Speed (%): ${currentCustom.speed.toInt()}",
            style: TextStyle(color: Colors.white)),
Slider(
  activeColor: Colors.orangeAccent,
  inactiveColor: Colors.grey,
  min: 10,
  max: 100,
  divisions: 18,
  value: currentCustom.speed,

  onChangeStart: (_) {
    // If starting below 80, lock it again
    if (currentCustom.speed < 80) {
      speedUnlocked = false;
    }
  },

  onChanged: (v) {
    setState(() {
      double snapped = (v / 5).round() * 5.0;

      // Block going past 80 unless unlocked
      if (!speedUnlocked && snapped > 80 && currentCustom.speed <= 80) {
        currentCustom.speed = 80;
      } else {
        currentCustom.speed = snapped;
      }
    });
  },

  onChangeEnd: (_) {
    // If user hit 80, allow next drag to go higher
    if (currentCustom.speed == 80) {
      speedUnlocked = true;
    }
  },
),

        Text("Turret: ${currentCustom.turret.toInt()}°",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.lightBlueAccent, inactiveColor: Colors.grey,
          min: -20, max: 20, divisions: 40,
          value: currentCustom.turret,
          onChanged: (v) => setState(() => currentCustom.turret = v),
        ),

        Text("Cowl: ${currentCustom.cowl.toInt()}°",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.purpleAccent, inactiveColor: Colors.grey,
          min: 0, max: 20, divisions: 20,
          value: currentCustom.cowl,
          onChanged: (v) => setState(() => currentCustom.cowl = v),
        ),

        Text("Spin: ${currentCustom.spin.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.greenAccent, inactiveColor: Colors.grey,
          min: -10, max: 10, divisions: 20,
          value: currentCustom.spin,
          onChanged: (v) => setState(() => currentCustom.spin = v),
        ),

        Text("Freq (s): ${currentCustom.freq.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.orangeAccent, inactiveColor: Colors.grey,
          min: 3, max: 12, divisions: 9,
          value: currentCustom.freq,
          onChanged: (v) => setState(() => currentCustom.freq = v),
        ),
      ],
    );
  }

  // ── Save dialog ───────────────────────────────────────────────────
  void _saveCustomSettings() {
    final controller = TextEditingController(
        text: currentCustom.id == "new_mode" ? "" : currentCustom.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text("Save Mode", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Name",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (currentCustom.id == "new_mode") {
                    final newProfile = Settings(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: controller.text,
                      speed: currentCustom.speed,
                      turret: currentCustom.turret,
                      cowl: currentCustom.cowl,
                      spin: currentCustom.spin,
                      freq: currentCustom.freq,
                    );
                    savedSettings.add(newProfile);
                    currentCustom = newProfile;
                  } else {
                    currentCustom.name = controller.text;
                    // Seq tab holds references to the same objects,
                    // so the name update is automatic.
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text("Save", style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // COURT WIDGET
  // ════════════════════════════════════════════════════════════════════
  Widget _buildCourt({required List<String> bottomGrid, required bool numbered}) {
    const double pad = 20;
    const double hit = 50;
    final double width  = 320 - 40;
    final double height = width * (44 / 20);

    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        border: Border.all(width: 3, color: Colors.white70),
        color: Colors.grey[850],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final kitchen = c.maxHeight * (7 / 44) - 20;
          return Column(
            children: [
              Expanded(
                child: Stack(children: [
                  Positioned(bottom: 0, left: 0, right: 0, height: kitchen,
                      child: Container(color: Colors.grey[700])),
                  _buildTopGrid(c, pad, hit, kitchen),
                ]),
              ),
              Container(height: 4, color: Colors.white),
              Expanded(
                child: Stack(children: [
                  Positioned(top: 0, left: 0, right: 0, height: kitchen,
                      child: Container(color: Colors.grey[700])),
                  _buildBottomGrid(c, pad, hit, kitchen, bottomGrid, numbered),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Top grid (machine position) ───────────────────────────────────
  Widget _buildTopGrid(BoxConstraints c, double pad, double hit, double kitchen) {
    final usableH = c.maxHeight / 2 - kitchen - pad * 2;
    final usableW = c.maxWidth - pad * 2;

    return Stack(
      children: [
        for (int r = 0; r < topGridSize; r++)
          for (int col = 0; col < topGridSize; col++)
            Positioned(
              left: pad + col * (usableW / (topGridSize - 1)) - hit / 2,
              top:  pad + r   * (usableH / (topGridSize - 1)) - hit / 2,
              child: GestureDetector(
                onTap: () => setState(() { topRow = r; topCol = col; }),
                child: Container(
                  width: hit, height: hit,
                  alignment: Alignment.center,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white70),
                  ),
                ),
              ),
            ),
        Positioned(
          left: pad + topCol * (usableW / (topGridSize - 1)) - 14,
          top:  pad + topRow * (usableH / (topGridSize - 1)) - 14,
          child: Icon(Icons.sports_tennis, size: 28, color: Colors.blueAccent),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // BOTTOM GRID — improved drag select
  //
  // Key fix: erase-vs-add is decided by the FIRST dot the finger touches.
  // If that dot is already selected  → the whole stroke erases.
  // If that dot is unselected        → the whole stroke adds.
  // This makes it completely predictable regardless of drag direction.
  // ════════════════════════════════════════════════════════════════════
  Widget _buildBottomGrid(
    BoxConstraints c, double pad, double hit, double kitchen,
    List<String> bottomGrid, bool numbered,
  ) {
    final usableH = c.maxHeight / 2 - kitchen - pad * 2;
    final usableW = c.maxWidth - pad * 2;

    String? keyAt(Offset local) {
      final col = ((local.dx - pad) / (usableW / (bottomGridSizeColumns - 1))).round();
      final row = ((local.dy - pad - kitchen) / (usableH / (bottomGridSizeRows - 1))).round();
      if (row < 0 || row >= bottomGridSizeRows ||
          col < 0 || col >= bottomGridSizeColumns) return null;
      return "$col,$row";
    }

    void handleDot(String key) {
      if (_dragVisited.contains(key)) return;
      _dragVisited.add(key);
      setState(() {
        if (_dragErasing == true) {
          bottomGrid.remove(key);
        } else {
          if (!bottomGrid.contains(key)) bottomGrid.add(key);
        }
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onPanStart: (details) {
        _dragVisited.clear();
        final key = keyAt(details.localPosition);
        if (key != null) {
          // Set intent from the FIRST dot touched
          _dragErasing = bottomGrid.contains(key);
          handleDot(key);
        } else {
          _dragErasing = false; // started outside grid, default to add
        }
      },

      onPanUpdate: (details) {
        if (_dragErasing == null) return;
        final key = keyAt(details.localPosition);
        if (key != null) handleDot(key);
      },

      onPanEnd: (_) {
        _dragVisited.clear();
        _dragErasing = null;
      },

      child: Stack(
        children: [
          for (int r = 0; r < bottomGridSizeRows; r++)
            for (int col = 0; col < bottomGridSizeColumns; col++)
              _buildBottomCell(
                  r, col, usableW, usableH, pad, hit, kitchen, bottomGrid, numbered),
        ],
      ),
    );
  }

  Widget _buildBottomCell(
    int r, int c, double w, double h,
    double pad, double hit, double kitchen,
    List<String> bottomGrid, bool numbered,
  ) {
    final key      = "$c,$r";
    final index    = bottomGrid.indexOf(key);
    final selected = index >= 0;

    final Color selColor;
    final Color unselColor;
    if (currentMode == AppMode.grid) {
      selColor   = gridSelectedColor;
      unselColor = gridUnselectedColor;
    } else if (currentMode == AppMode.random) {
      selColor   = randomSelectedColor;
      unselColor = randomUnselectedColor;
    } else {
      selColor   = Colors.redAccent;
      unselColor = Colors.white70;
    }

    return Positioned(
      left: pad + c * (w / (bottomGridSizeColumns - 1)) - hit / 2,
      top:  pad + kitchen + r * (h / (bottomGridSizeRows - 1)) - hit / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (bottomGrid.contains(key)) bottomGrid.remove(key);
            else bottomGrid.add(key);
          });
        },
        child: Container(
          width: hit, height: hit,
          alignment: Alignment.center,
          child: Container(
            width: 30, height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? selColor : unselColor,
            ),
            child: (numbered && selected)
                ? Text("${index + 1}",
                    style: TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SHARED CONTROLS
  // ════════════════════════════════════════════════════════════════════
Widget _buildPatternButtons() {
  return Column(
    children: [
      // CLEAR button (top)
      _selectButton(
        "Clear",
        clearGridActive,
        () {
          setState(() {
            bottomSelectionOrder.clear();
            clearGridActive = true;
          });
          Future.delayed(Duration(milliseconds: 150),
              () => setState(() => clearGridActive = false));
        },
        activeColor: Colors.redAccent,
        fontSize: 14,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      SizedBox(height: 10),

      // First pattern
      _selectButton(
        "1-8,8-1",
        pattern == "1-8,8-1",
        () => setState(() => pattern = "1-8,8-1"),
      ),

      SizedBox(height: 8),

      // Second pattern
      _selectButton(
        "1-8,1-8",
        pattern == "1-8,1-8",
        () => setState(() => pattern = "1-8,1-8"),
      ),
    ],
  );
}

  Widget _buildSpeedRow() {
    return Padding(
      padding: EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Text("Speed:", style: TextStyle(fontSize: 20, color: Colors.white)),
          SizedBox(width: 12),
          _selectButton("Slow", speedPattern == "Slow",
              () => setState(() => speedPattern = "Slow")),
          SizedBox(width: 8),
          _selectButton("Med", speedPattern == "Medium",
              () => setState(() => speedPattern = "Medium")),
          SizedBox(width: 8),
          _selectButton("Fast", speedPattern == "Fast",
              () => setState(() => speedPattern = "Fast")),
        ],
      ),
    );
  }

  Widget _buildSpeedAdjustmentSlider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Speed adj: ${speedAdjustment.toInt()}",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Slider(
            activeColor: Colors.lightBlueAccent, inactiveColor: Colors.grey,
            min: 0, max: 10, divisions: 10,
            value: speedAdjustment,
            onChanged: (v) => setState(() => speedAdjustment = v),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFreqSlider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Freq (s): ${freq.toInt()}",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Slider(
            activeColor: Colors.orangeAccent, inactiveColor: Colors.grey,
            min: 3, max: 12, divisions: 9,
            value: freq,
            onChanged: (v) => setState(() => freq = v),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // START / STOP
  // ════════════════════════════════════════════════════════════════════
  Widget _buildStartStop() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _selectButton("START", isRunning,
              () => setState(() => isRunning = true),
              activeColor: Colors.greenAccent, fontSize: 24,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24)),
          _selectButton("STOP", !isRunning,
              () => setState(() => isRunning = false),
              activeColor: Colors.redAccent, fontSize: 24,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // DEBUG MODE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildDebugMode() {
    Widget kv(String k, String v) => Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: "$k: ",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(text: v,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
    );

    Widget section(String title, Color color, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        ...children,
        SizedBox(height: 18),
      ],
    );

    final effectiveSeq = _buildEffectiveSequence();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),

          section("GRID", Colors.lightBlueAccent, [
            kv("Top pos",   "col $topCol  row $topRow"),
            kv("Dots",      bottomSelectionOrder.isEmpty ? "None" : bottomSelectionOrder.join(" → ")),
            kv("Pattern",   pattern),
            kv("Speed",     speedPattern),
            kv("Speed adj", "${speedAdjustment.toInt()}x"),
            kv("Freq",      "${freq.toInt()}s"),
          ]),

          section("RANDOM", Colors.redAccent, [
            kv("Dots",      randomBottomSelection.isEmpty ? "None" : randomBottomSelection.join(", ")),
            kv("Speed",     speedPattern),
            kv("Speed adj", "${speedAdjustment.toInt()}x"),
            kv("Freq",      "${freq.toInt()}s"),
          ]),

          section("CUSTOM", Colors.orangeAccent, [
            kv("Mode",   currentCustom.name),
            kv("Speed",  "${currentCustom.speed.toInt()}%"),
            kv("Turret", "${currentCustom.turret.toInt()}°"),
            kv("Cowl",   "${currentCustom.cowl.toInt()}°"),
            kv("Spin",   "${currentCustom.spin.toInt()}"),
            kv("Freq",   "${currentCustom.freq.toInt()}s"),
          ]),

          section("SEQ", Colors.purpleAccent, [
            kv("Direction", _directionLabel(sequenceDirection)),
            kv("Timing",    timingMode == TimingMode.perShot
                ? "Per-shot" : "Global ${globalFreq.toInt()}s"),
            kv("Order",     sequenceList.isEmpty ? "Empty"
                : sequenceList.map((s) => s.name).join(" → ")),
            kv("Playback",  effectiveSeq.isEmpty ? "Empty"
                : effectiveSeq.map((s) => s.name).join(" → ")),
            if (effectiveSeq.isNotEmpty) ...[
              SizedBox(height: 4),
              ...effectiveSeq.asMap().entries.map((e) {
                final f = timingMode == TimingMode.global
                    ? globalFreq.toInt() : e.value.freq.toInt();
                return kv("  ${e.key + 1}. ${e.value.name}", "freq ${f}s");
              }),
            ],
          ]),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  List<Settings> _buildEffectiveSequence() {
    if (sequenceList.isEmpty) return [];
    switch (sequenceDirection) {
      case SequenceDirection.topToBottom:
        return List.from(sequenceList);
      case SequenceDirection.bottomToTop:
        return List.from(sequenceList.reversed);
    }
  }

  String _directionLabel(SequenceDirection d) {
    switch (d) {
      case SequenceDirection.topToBottom: return "Top → Bottom | Bottom → Top";
      case SequenceDirection.bottomToTop: return "Bottom → Top";
    }
  }

  // ── Generic button ────────────────────────────────────────────────
  Widget _selectButton(
    String text, bool active, VoidCallback onTap, {
    Color activeColor = Colors.blueAccent,
    double fontSize   = 18,
    EdgeInsets padding =
        const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: TextStyle(
              fontSize: fontSize,
              color: active ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}
// the end