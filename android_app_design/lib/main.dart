import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

enum AppMode { grid, custom, random, debug }

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
  
    // ---------------- DRAG SELECTION ----------------
  bool isDragging = false;
  Set<String> dragVisited = {};

  Offset? dragStart;
bool eraseMode = false;

// Dot colors for Grid mode
final Color gridSelectedColor = const Color.fromARGB(255, 55, 215, 37);
final Color gridUnselectedColor = Colors.white70;

// Dot colors for Random mode
final Color randomSelectedColor = const Color.fromARGB(255, 229, 25, 25);
final Color randomUnselectedColor = Colors.white54;

bool isConnected = false; // default state
bool debugMode = false; // tracks if debug is active
bool clearGridActive = false; 
bool randomClearActive = false; 

  // ---------------- CONNECTION BUTTON ----------------
  Widget _buildConnectionButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isConnected = !isConnected;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isConnected ? "Connected" : "Disconnected",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton() {
  return GestureDetector(
    onTap: () {
      setState(() {
        currentMode = AppMode.debug;
      });
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: currentMode == AppMode.debug ? const Color.fromARGB(255, 219, 144, 15) : Colors.grey[700], // active color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Debug",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}

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
appBar: PreferredSize(
  preferredSize: Size.fromHeight(30), // smaller than default 56
  child: AppBar(
    title: const SizedBox.shrink(),
    backgroundColor: Colors.grey[900],
    elevation: 0, // optional, removes shadow
  ),
),
body: Stack(
  children: [
    // Main content in a Column
    Column(
      children: [
        Row(
          children: [
            SizedBox(width: 14),
            _buildConnectionButton(),
          ],
        ),
        SizedBox(height: 16),
        _buildModeSelector(),
        SizedBox(height: 8),
        Expanded(child: _buildModeContent()),
        _buildStartStop(),
      ],
    ),

    // Debug button in top-right
    Positioned(
      top: 3,
      right: 14,
      child: _buildDebugButton(),
    ),
  ],
),
    );
  }

  // ---------------- MODE SELECTOR ----------------
  Widget _buildModeSelector() {
    Widget button(String text, AppMode mode, {double fontSize = 18}) {
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
                    fontSize: 26,
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
        button("Grid", AppMode.grid,fontSize: 24),
        button("Custom", AppMode.custom, fontSize: 20),
        button("Random", AppMode.random, fontSize: 20),
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
      case AppMode.debug:
        return _buildDebugMode();
    }
  }

  // ---------------- GRID MODE ----------------
Widget _buildGridMode() {
  return SingleChildScrollView(
    child: Column(
      children: [
        SizedBox(height: 12),

        _buildCourt(
          bottomGrid: bottomSelectionOrder,
          numbered: true,
        ),

        SizedBox(height: 20),

        _buildPatternButtons(), // this now contains the Clear button

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

        SizedBox(height: 12),

_selectButton(
  "Clear Grid",
  randomClearActive,
  () {
    setState(() {
      randomBottomSelection.clear(); // clear random grid
      randomClearActive = true;      // activate the highlight
    });

    Future.delayed(Duration(milliseconds: 150), () {
      setState(() {
        randomClearActive = false;  // reset after short delay
      });
    });
  },
  activeColor: Colors.redAccent,
),

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
                  Future.delayed(Duration(milliseconds: 150),
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
                    width:32,
                    height: 32,
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

Widget selectedDotsDisplay(List<String> dots) {
  if (dots.isEmpty) {
    return Text(
      "None",
      style: TextStyle(color: Colors.white70, fontSize: 16),
    );
  }

  return Wrap(
    spacing: 6,
    runSpacing: 4,
    children: dots.map((dot) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          dot,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }).toList(),
  );
}

  // ---------------- DEBUG MODE ----------------
Widget _buildDebugMode() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: 16),

        // ---------------- GRID MODE ----------------
        Text(
          "GRID MODE",
          style: TextStyle(color: Colors.lightBlueAccent, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text("Top Grid Selected Position:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Row: $topRow, Col: $topCol", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Bottom Grid Selected Dots (Order):", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        selectedDotsDisplay(bottomSelectionOrder),
        SizedBox(height: 4),
        Text("Pattern Selected:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(pattern, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Speed:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(speedPattern, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Speed Adjustment:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${speedAdjustment.toInt()}%", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Frequency:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${freq.toInt()}s", style: TextStyle(color: Colors.white70, fontSize: 16)),

        SizedBox(height: 20),

                // ---------------- CUSTOM MODE ----------------
        Text(
          "CUSTOM MODE",
          style: TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text("Selected Mode:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(currentCustom.name, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Speed:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${currentCustom.speed.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Turret:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${currentCustom.turret.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Cowl:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${currentCustom.cowl.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Spin:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${currentCustom.spin.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Frequency:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${currentCustom.freq.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 16)),

       SizedBox(height: 20),

        // ---------------- RANDOM MODE ----------------
        Text(
          "RANDOM MODE",
          style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text("Top Grid Selected Position:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Row: $topRow, Col: $topCol", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Bottom Grid Selected Dots (Order):", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        selectedDotsDisplay(randomBottomSelection),
        SizedBox(height: 4),
        Text("Speed:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(speedPattern, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Speed Adjustment:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${speedAdjustment.toInt()}%", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 4),
        Text("Frequency:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("${freq.toInt()}s", style: TextStyle(color: Colors.white70, fontSize: 16)),

        SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildBottomGrid(
  BoxConstraints c,
  double pad,
  double hit,
  double kitchen,
  List<String> bottomGrid,
  bool numbered,
) {
  final usableH = c.maxHeight / 2 - kitchen - pad * 2;
  final usableW = c.maxWidth - pad * 2;

  return GestureDetector(
    behavior: HitTestBehavior.opaque,

onPanStart: (details) {
  dragVisited.clear();
  dragStart = details.localPosition;
},

onPanUpdate: (details) {
  final local = details.localPosition;

  // Decide erase vs add based on drag direction
  if (dragStart != null) {
    final delta = local - dragStart!;
    eraseMode = delta.dy < 0; // dragging up = erase
  }

  final col =
      ((local.dx - pad) / (usableW / (bottomGridSizeColumns - 1))).round();
  final row =
      ((local.dy - pad - kitchen) / (usableH / (bottomGridSizeRows - 1)))
          .round();

  if (row < 0 ||
      row >= bottomGridSizeRows ||
      col < 0 ||
      col >= bottomGridSizeColumns) return;

  final key = "$row,$col";

  if (!dragVisited.contains(key)) {
    dragVisited.add(key);
    setState(() {
      if (eraseMode) {
        bottomGrid.remove(key);
      } else {
        if (!bottomGrid.contains(key)) bottomGrid.add(key);
      }
    });
  }
},

onPanEnd: (_) {
  dragVisited.clear();
  dragStart = null;
  eraseMode = false;
},

    child: Stack(
      children: [
        for (int r = 0; r < bottomGridSizeRows; r++)
          for (int col = 0; col < bottomGridSizeColumns; col++)
            _buildBottomCell(
              r,
              col,
              usableW,
              usableH,
              pad,
              hit,
              kitchen,
              bottomGrid,
              numbered,
            ),
      ],
    ),
  );
}

Widget _buildBottomCell(
    int r,
    int c,
    double w,
    double h,
    double pad,
    double hit,
    double kitchen,
    List<String> bottomGrid,
    bool numbered,
) {
  final key = "$r,$c";
  final index = bottomGrid.indexOf(key);
  final isSelected = index >= 0;

  // ----------------- Colors based on mode -----------------
  Color selectedColor;
  Color unselectedColor;

  if (currentMode == AppMode.grid) {
    selectedColor = gridSelectedColor;    // e.g., Colors.redAccent
    unselectedColor = gridUnselectedColor; // e.g., Colors.white70
  } else if (currentMode == AppMode.random) {
    selectedColor = randomSelectedColor;    // e.g., Colors.greenAccent
    unselectedColor = randomUnselectedColor; // e.g., Colors.white54
  } else {
    selectedColor = Colors.redAccent;
    unselectedColor = Colors.white70;
  }

  // ----------------- Return cell -----------------
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
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? selectedColor : unselectedColor, // <-- USE HERE
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
      Container(
        width: double.infinity, // ensure full width
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered 1-8 button
            _selectButton(
              "1-8,8-1",
              pattern == "1-8,8-1",
              () => setState(() => pattern = "1-8,8-1"),
            ),

            // Clear button on the right
Positioned(
  right: 70,
  child: _selectButton(
    "Clear Grid",
    clearGridActive, // <-- use this variable instead of false
    () {
      setState(() {
        bottomSelectionOrder.clear(); // clear the grid
        clearGridActive = true;       // trigger highlight
      });

      // Reset the highlight after 300 milliseconds
      Future.delayed(Duration(milliseconds: 150), () {
        setState(() {
          clearGridActive = false;
        });
      });
    },
    activeColor: Colors.redAccent,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    fontSize: 14,
  ),
),
          ],
        ),
      ),

      SizedBox(height: 8),

      // Second pattern button stays below
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
//the end