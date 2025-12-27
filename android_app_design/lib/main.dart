import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

enum AppMode { grid, custom, random }

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
  // ---------------- MODE ----------------
  AppMode currentMode = AppMode.grid;

  // ---------------- GRID MODE ----------------
  static const int topGridSize = 5;
  static const int bottomGridSizeColumns = 7;
  static const int bottomGridSizeRows = 5;
  int topRow = 2, topCol = 2;
  List<String> bottomSelectionOrder = [];

  // ---------------- RANDOM MODE ----------------
  List<String> randomBottomSelection = [];


  // Pattern / speed / frequency
  String pattern = "1-8,8-1";
  String speedPattern = "Medium";
  double freq = 7;

   // ---------- NEW SPEED ADJUSTMENT ----------
  double speedAdjustment = 0;

  // ---------------- CUSTOM MODE ----------------
  final Settings newModeTemplate = Settings(
      id: "new_mode",
      name: "New mode",
      speed: 10,
      turret: 0,
      cowl: 0,
      spin: 0,
      freq: 7);

  late Settings currentCustom;
  late List<Settings> savedSettings;

  // ---------------- START/STOP ----------------
  bool isRunning = false;

  // Test shot
  bool testShotActive = false;

  @override
  void initState() {
    super.initState();
    savedSettings = [newModeTemplate];
    currentCustom = newModeTemplate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          _buildModeSelector(),
          SizedBox(height: 8),
          Expanded(child: _buildModeContent()),
          _buildStartStop(),
        ],
      ),
    );
  }

  // ---------------- MODE SELECTOR ----------------
  Widget _buildModeSelector() {
    Widget button(String text, AppMode mode) {
      bool active = currentMode == mode;
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => setState(() => currentMode = mode),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: active ? Colors.blueAccent : Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 18,
                    color: active ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(width: 8),
        button("Grid", AppMode.grid),
        button("Custom", AppMode.custom),
        button("Random", AppMode.random),
        SizedBox(width: 8),
      ],
    );
  }

  // ---------------- MODE CONTENT ----------------
  Widget _buildModeContent() {
    switch (currentMode) {
      case AppMode.grid:
        return _buildGridMode();
      case AppMode.custom:
        return _buildCustomMode();
      case AppMode.random:
        return _buildRandomMode();
    }
  }

  // ---------------- GRID MODE ----------------
  Widget _buildGridMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          _buildCourt(bottomGrid: bottomSelectionOrder, numbered: true),
          SizedBox(height: 20),
          _buildPatternButtons(),
          SizedBox(height: 16),
          _buildSpeedRow(),
          SizedBox(height: 16),
          _buildSpeedAdjustmentSlider(),
          _buildFreqSlider(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------- SPEED ADJUSTMENT SLIDER ----------------
Widget _buildSpeedAdjustmentSlider() {
  // Make sure this variable exists in your state class:
  // double speedAdjustment = 0;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Speed adjustment (%): ${speedAdjustment.toInt()}",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        Slider(
          activeColor: Colors.lightBlueAccent,
          inactiveColor: Colors.grey,
          min: -20,
          max: 20,
          divisions: 40,
          value: speedAdjustment,
          onChanged: (double value) {
            setState(() {
              speedAdjustment = value;
            });
          },
        ),
        SizedBox(height: 12), // spacing below the slider
      ],
    ),
  );
}

  // ---------------- RANDOM MODE ----------------
  Widget _buildRandomMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          _buildCourt(bottomGrid: randomBottomSelection, numbered: false),
          SizedBox(height: 20),
          _buildSpeedRow(),
          SizedBox(height: 16),
          _buildSpeedAdjustmentSlider(),
          _buildFreqSlider(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------- CUSTOM MODE ----------------
  Widget _buildCustomMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mode:", style: TextStyle(fontSize: 16, color: Colors.white)),
            SizedBox(height: 8),
            DropdownButton<Settings>(
              dropdownColor: Colors.grey[850],
              value: currentCustom,
              items: savedSettings
                  .map((s) => DropdownMenuItem(
                        child: Text(s.name,
                            style: TextStyle(color: Colors.white)),
                        value: s,
                      ))
                  .toList(),
              onChanged: (s) {
                if (s != null) setState(() => currentCustom = s);
              },
            ),
            SizedBox(height: 16),
            _buildCustomSliders(),
            SizedBox(height: 12),
            Row(
              children: [
                _selectButton("Save", true, _saveCustomSettings,
                    activeColor: Colors.orangeAccent),
                SizedBox(width: 12),
                _selectButton("Test Shot", testShotActive, () {
                  setState(() => testShotActive = true);
                  Future.delayed(Duration(milliseconds: 300),
                      () => setState(() => testShotActive = false));
                }, activeColor: Colors.pinkAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- CUSTOM SLIDERS ----------------
  Widget _buildCustomSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speed slider with safety stop
        Text("Speed (%): ${currentCustom.speed.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.orangeAccent,
          inactiveColor: Colors.grey,
          min: 10,
          max: 100,
          divisions: 18,
          value: currentCustom.speed,
          onChanged: (v) {
            if (v > 80 && currentCustom.speed < 80) {
              setState(() => currentCustom.speed = 80);
            } else {
              setState(() => currentCustom.speed = (v / 5).round() * 5.0);
            }
          },
          onChangeEnd: (v) {
            if (v > 80) setState(() => currentCustom.speed = 100);
          },
        ),

        // Turret Angle
        Text("Turret Angle: ${currentCustom.turret.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.lightBlueAccent,
          inactiveColor: Colors.grey,
          min: -20,
          max: 20,
          divisions: 40,
          value: currentCustom.turret,
          onChanged: (v) => setState(() => currentCustom.turret = v),
        ),

        // Cowl Angle
        Text("Cowl Angle: ${currentCustom.cowl.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.purpleAccent,
          inactiveColor: Colors.grey,
          min: 0,
          max: 20,
          divisions: 20,
          value: currentCustom.cowl,
          onChanged: (v) => setState(() => currentCustom.cowl = v),
        ),

        // Spin
        Text("Spin (Back-Top): ${currentCustom.spin.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.greenAccent,
          inactiveColor: Colors.grey,
          min: -10,
          max: 10,
          divisions: 20,
          value: currentCustom.spin,
          onChanged: (v) => setState(() => currentCustom.spin = v),
        ),

        // Frequency
        Text("Frequency (s): ${currentCustom.freq.toInt()}",
            style: TextStyle(color: Colors.white)),
        Slider(
          activeColor: Colors.orangeAccent,
          inactiveColor: Colors.grey,
          min: 3,
          max: 12,
          divisions: 9,
          value: currentCustom.freq,
          onChanged: (v) => setState(() => currentCustom.freq = v),
        ),
      ],
    );
  }

  // ---------------- SAVE LOGIC ----------------
  void _saveCustomSettings() {
    TextEditingController controller = TextEditingController();
    controller.text =
        currentCustom.id == "new_mode" ? "" : currentCustom.name;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text("Save Settings", style: TextStyle(color: Colors.white)),
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
              child: Text("Cancel", style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    if (currentCustom.id == "new_mode") {
                      // Create new profile
                      Settings newProfile = Settings(
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
                      // Update existing profile
                      currentCustom.name = controller.text;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("Save", style: TextStyle(color: Colors.orangeAccent))),
        ],
      ),
    );
  }


  
  // ---------------- COURT & GRID ----------------
  Widget _buildCourt({required List<String> bottomGrid, required bool numbered}) {
    double width = (320-40);
    double height = width * (44 / 20);
    const double pad = 20; //was 28
    const double hit = 50; // was 56

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(width: 3, color: Colors.white70),
        color: Colors.grey[850],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final kitchen = c.maxHeight * (7 / 44)-20;

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: kitchen,
                      child: Container(color: Colors.grey[700]),
                    ),
                    _buildTopGrid(c, pad, hit, kitchen),
                  ],
                ),
              ),
              Container(height: 4, color: Colors.white),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: kitchen,
                      child: Container(color: Colors.grey[700]),
                    ),
                    _buildBottomGrid(c, pad, hit, kitchen, bottomGrid, numbered),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopGrid(BoxConstraints c, double pad, double hit, double kitchen) {
    final usableH = (c.maxHeight / 2 - kitchen - pad * 2);
    final usableW = (c.maxWidth - pad * 2);

    return Stack(
      children: [
        for (int r = 0; r < topGridSize; r++)
          for (int col = 0; col < topGridSize; col++)
            Positioned(
              left: pad + col * (usableW / (topGridSize - 1)) - hit / 2,
              top: pad + r * (usableH / (topGridSize - 1)) - hit / 2,
              child: GestureDetector(
                onTap: () => setState(() {
                  topRow = r;
                  topCol = col;
                }),
                child: Container(
                  width: hit,
                  height: hit,
                  alignment: Alignment.center,
                  child: Container(
                    width:24,
                    height: 24,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white70),
                  ),
                ),
              ),
            ),
        Positioned(
          left: pad + topCol * (usableW / (topGridSize - 1)) - 14,
          top: pad + topRow * (usableH / (topGridSize - 1)) - 14,
          child: Icon(Icons.sports_tennis, size: 28, color: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildBottomGrid(BoxConstraints c, double pad, double hit, double kitchen,
      List<String> bottomGrid, bool numbered) {
    final usableH = c.maxHeight / 2 - kitchen - pad * 2;
    final usableW = c.maxWidth - pad * 2;

    return Stack(
      children: [
        for (int r = 0; r < bottomGridSizeRows; r++)
          for (int col = 0; col < bottomGridSizeColumns; col++)
            _buildBottomCell(r, col, usableW, usableH, pad, hit, kitchen,
                bottomGrid, numbered),
      ],
    );
  }

  Widget _buildBottomCell(int r, int c, double w, double h, double pad, double hit,
      double kitchen, List<String> bottomGrid, bool numbered) {
    final key = "$r,$c";
    final index = bottomGrid.indexOf(key);
    final isSelected = index >= 0;

    return Positioned(
      left: pad + c * (w / (bottomGridSizeColumns - 1)) - hit / 2,
      top: pad + kitchen + r * (h / (bottomGridSizeRows - 1)) - hit / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (bottomGrid.contains(key))
              bottomGrid.remove(key);
            else
              bottomGrid.add(key);
          });
        },
        child: Container(
          width: hit,
          height: hit,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.redAccent : Colors.white70,
            ),
            child: (numbered && isSelected)
                ? Text(
                    "${index + 1}",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ---------------- PATTERN / SPEED / FREQ ----------------
  Widget _buildPatternButtons() {
    return Column(
      children: [
        _selectButton("1-8,8-1", pattern == "1-8,8-1",
            () => setState(() => pattern = "1-8,8-1")),
        SizedBox(height: 8),
        _selectButton("1-8,1-8", pattern == "1-8,1-8",
            () => setState(() => pattern = "1-8,1-8")),
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
          _selectButton("Medium", speedPattern == "Medium",
              () => setState(() => speedPattern = "Medium")),
          SizedBox(width: 8),
          _selectButton("Fast", speedPattern == "Fast",
              () => setState(() => speedPattern = "Fast")),
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
          Text("Frequency (s): ${freq.toInt()}", style: TextStyle(color: Colors.white, fontSize: 18)),
          Slider(
            activeColor: Colors.orangeAccent,
            inactiveColor: Colors.grey,
            min: 3,
            max: 12,
            divisions: 9,
            value: freq,
            onChanged: (v) => setState(() => freq = v),
          ),
        ],
      ),
    );
  }

// ---------------- START/STOP BUTTONS ----------------
Widget _buildStartStop() {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _selectButton(
          "START",
          isRunning,
          () => setState(() => isRunning = true),
          activeColor: Colors.greenAccent,
          fontSize: 25, // bigger text
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // bigger button
        ),
        _selectButton(
          "STOP",
          !isRunning,
          () => setState(() => isRunning = false),
          activeColor: Colors.redAccent,
          fontSize: 25,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        ),
      ],
    ),
  );
}

// ---------------- GENERIC BUTTON ----------------
Widget _selectButton(
  String text,
  bool active,
  VoidCallback onTap, {
  Color activeColor = Colors.blueAccent,
  double fontSize = 18, // default text size
  EdgeInsets padding =
      const EdgeInsets.symmetric(vertical: 8, horizontal: 14), // default padding
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding, // configurable padding
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize, // configurable text size
          color: active ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
}