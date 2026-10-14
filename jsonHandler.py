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
<<<<<<< Updated upstream

def handle_json(data):
    connected = True
    global currentMode, freq, numBalls, power, speedAdjustment, topRow, topCol, testShotActive, isRunning, customSpeed, customTurret, customCowl, customSpin, customFreq, gridSel
=======
sequence = []
sequenceDirection = "topToBottom"
timing = "perShot"
gFreq = 7
savedCustoms = []
liveAim = False

def reset():
    global currentMode, numCycles, freq, numBalls, power, speedAdjustment, topRow, topCol, testShotActive, isRunning, customSpeed, customTurret, customCowl
    global customSpin, customFreq, gridSel, sequence, sequenceDirection, savedCustoms, liveAim, randomBottomSelection, timing, gFreq
    currentMode = "Appmode.grid"
    freq = 7
    numBalls = 10
    numCycles = 1
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
    sequence = []
    sequenceDirection = "topToBottom"
    timing = "perShot"
    gFreq = 7    
    savedCustoms = []
    liveAim = False

def parseCoords(v):
    if isinstance(v, str):
        v = [s for s in v.strip("[]").split(", ") if s]
    out = []
    for s in v:
        try:
            x, y = s.split(",")
            out.append([int(x), int(y)])
        except Exception as e:
            print("Bad Coord: ", s, e)
    return out

def handle_json(data):
    global currentMode, freq, numBalls, numCycles, power, speedAdjustment, topRow, topCol, testShotActive, isRunning, customSpeed, timing
    global gFreq, customTurret, customCowl, customSpin, customFreq, gridSel, sequence, sequenceDirection, savedCustoms, liveAim, randomBottomSelection, pattern
>>>>>>> Stashed changes
    try:
        obj = data
        if "cm" in obj:
            currentMode = obj["cm"]
            print("CustomMode: ", currentMode)
        if "f" in obj:
            freq = obj["f"]
            print("freq: ", freq)
        if "la" in obj:
            liveAim = obj["la"]
            print("liveAim: ", liveAim)
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
<<<<<<< Updated upstream
=======
        
        if "sq" in obj:
            if obj["sq"] != "":
                sequence = obj["sq"].split(",")
                sequence = [int(x) for x in sequence]
                print("Seq order:", sequence)
            else:
                sequence = []
                print("Seq order:", sequence)
        
        if "sqd" in obj:
            sequenceDirection = obj["sqd"]
            print("Seq direction:", sequenceDirection)
            
        if "tm" in obj:
            timing = obj["tm"]
            print("Timing:", timing)
        if "gf" in obj:
            gFreq = obj["gf"]
            print("Global freq:", gFreq)       
        
            
        if "sc" in obj:
            if obj["sc"] != '[]':
                sc = obj["sc"].split("|")
                savedCustoms = []
                for custom in sc:
                    custom = custom[1:-1]
                    try:
                        id,s,t,c,p,f = custom.split(",")
                        id = int(id)
                        s = float(s)
                        t = float(t)
                        c = float(c)
                        p = float(p)
                        f = float(f)
                        savedCustoms.append([id,s,t,c,p,f])
                    except Exception as e:
                        print("Bad custom: ", custom, ", with error: ", e)
                print("Saved Customs: ", savedCustoms)
            else:
                savedCustoms = []
                print("Saved Customs: ", savedCustoms)
                    
        if "pa" in obj:
            pattern = obj["pa"]
>>>>>>> Stashed changes
        if "g" in obj:
            gridSel = parseCoords(obj["g"])
            print("Grid Selection: ", gridSel)
        if "rbs" in obj:
            randomBottomSelection = parseCoords(obj["rbs"])
            print("Random Selection: ", randomBottomSelection)
        
    except Exception as e:
        print("JSON parse error:", e)