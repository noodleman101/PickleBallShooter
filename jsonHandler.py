################################
#	handle_json(data)
#	- Takes in an input of a raw read json
#
################################
# JSON Characteristics:
currentMode = "Appmode.grid"
freq = 7
numBalls = 10
power = "Medium"
speedAdjustment = 0
topRow = 0
topCol = 0
testShotActive = False
isRunning = False
customSpeed = 10
customTurret = 0
customCowl = 0
customSpin = 0
customFreq = 7
gridSel = []
pattern = "1-8|8-1"
randomBottomSelection = []

def handle_json(data):
    connected = True
    global currentMode, freq, numBalls, power, speedAdjustment, topRow, topCol, testShotActive, isRunning, customSpeed, customTurret, customCowl, customSpin, customFreq, gridSel
    try:
        obj = data
        if "cm" in obj:
            currentMode = obj["cm"]
            print("CustomMode: ", currentMode)
        if "f" in obj:
            freq = obj["f"]
            print("freq: ", freq)
        if "n" in obj:
            numBalls = obj["n"]
            print("numBalls: ", numBalls)
        if "p" in obj:
            power = obj["p"]
            print("power: ", power)
        if "sa" in obj:
            speedAdjustment = obj["sa"]
            print("speedAdjustment: ", speedAdjustment)
        if "tr" in obj:
            topRow = obj["tr"]
            print("topRow: ", topRow)
        if "tc" in obj:
            topCol = obj["tc"]
            print("topCol: ", topCol)
        if "ts" in obj:
            if obj["ts"]:
                testShotActive = obj["ts"]
            print("testShotActive: ", testShotActive)
        if "r" in obj:
            isRunning = obj["r"]
            print("isRunning: ", isRunning)
        if "cc" in obj:
            cc = obj.get("cc")
            if "s" in cc:
                customSpeed = cc["s"]
                print("CustomSpeed: ", customSpeed)
            if "t" in cc:
                customTurret = cc["t"]
                print("CustomTurret: ", customTurret)
            if "c" in cc:
                customCowl = cc["c"]
                print("CustomCowl: ", customCowl)
            if "p" in cc:
                customSpin = cc["p"]
                print("CustomSpin: ", customSpin)
            if "f" in cc:
                customFreq = cc["f"]
                print("CustomFreq: ", customFreq)
        if "g" in obj:
            if obj["g"]!="[]":
                gridSel = obj["g"]
                g = gridSel[1:-1]
                g = g.split(", ")
                gridSel = []
                for s in g:
                    try:
                        x_str,y_str = s.split(",")
                        x = int(x_str)
                        y = int(y_str)
                        gridSel.append([x,y])
                    except Exception as e:
                        print("Bad Coord: ", s, e)
                print("Grid Selection: ", gridSel)
                
            else:
                gridSel = []
                print("Grid Selection: ", gridSel)
        if "rbs" in obj:
                if obj["rbs"]!="[]":
                    randomBottomSelection = obj["rbs"]
                    rbs = randomBottomSelection[1:-1]
                    rbs = rbs.split(", ")
                    randomBottomSelection = []
                    for s in rbs:
                        try:
                            x_str,y_str = s.split(",")
                            x = int(x_str)
                            y = int(y_str)
                            randomBottomSelection.append([x,y])
                        except Exception as e:
                            print("Bad Coord: ", s, e)
                    print("Random Bottom Selection: ", randomBottomSelection)
                    
                else:
                    randomBottomSelection = []
                    print("Random Bottom Selection: ", randomBottomSelection)
    except Exception as e:
        print("JSON parse error:", e)