import aioble
import asyncio
from machine import Pin,PWM
from micropython import const
import time
import jsonHandler as jh
import bluetoothHandler as bt
import motors
from picozero import pico_led
<<<<<<< Updated upstream
=======
from simple_pid import PID
import random
import math
import interpolation as ip

#nothing
lowerCounter0 = 0
def lowerCounter(pin):
    global lowerCounter0
    lowerCounter0 += 1
upperCounter0 = 0
def upperCounter(pin):
    global upperCounter0
    upperCounter0 += 1
>>>>>>> Stashed changes

shooterLower = motors.ShooterMotor(shooterPWM = 27, shooterEN = 28)
shooterUpper = motors.ShooterMotor(shooterPWM = 22, shooterEN = 26)

feederMotor = motors.Stepper(16,17,15, 1)
feederMotor.disable()

cowlMotor = motors.Stepper(18,19,14, 4600/264)
cowlMotor.disable()
cowlAngle = 0

turretMotor = motors.Stepper(20,21,13,70/18)
turretMotor.disable()
turretAngle = 0

DEBUG_RPM = False   # True = print RPM readout
  
async def feed():
    print("we shootin fr fr")
    feederMotor.enable()
    feederMotor.move(180,500,0)
    feederMotor.disable()
    
isRunning0 = False
timer = 0
shotCount = 0

async def custom():
    global isRunning0, timer, shotCount
    isRunning = jh.isRunning
    testShotActive = jh.testShotActive

    if isRunning and not isRunning0:
        customSpinUp()
        timer = time.time_ns()
        shotCount = 0
    elif not isRunning and isRunning0:
<<<<<<< Updated upstream
        shooterLower.rampDown(1000,0.05)
        shooterUpper.rampDown(1000,0.05)
=======
        customSpinDown()
        if not jh.liveAim:
            await moveAim(0, 0)
>>>>>>> Stashed changes
    isRunning0 = isRunning

    if isRunning:
<<<<<<< Updated upstream
        if shotCount == jh.numBalls:
=======
        if jh.numBalls != 25 and shotCount >= jh.numBalls:
>>>>>>> Stashed changes
            jh.isRunning = False
            isRunning = False
        if timer != 0:
            await moveAim(jh.customCowl, jh.customTurret)
        elif isRunning:
            await moveAim(jh.customCowl, jh.customTurret, doFeed=True)
            timer = time.time_ns()
            shotCount = shotCount + 1
        if (time.time_ns() - timer > jh.customFreq*1000000000):
            timer = 0
<<<<<<< Updated upstream
            
            
    
    if cowlAngle != jh.customCowl:
        cowlMotor.enable()
        cowlMotor.move(abs(jh.customCowl - cowlAngle), 200, 0 if jh.customCowl > cowlAngle else 1)
        cowlAngle = jh.customCowl
        time.sleep(0.25)
        if cowlAngle == 0:
            cowlMotor.disable()
        
    if turretAngle != jh.customTurret:
        turretMotor.enable()
        turretMotor.move(abs(jh.customTurret - turretAngle), 1000, 1 if jh.customTurret > turretAngle else 0)
        
        turretAngle = jh.customTurret
        turretMotor.disable()
    
    if testShotActive:
        await feed()
        jh.testShotActive = False
 
=======
    else:
        if testShotActive:
            customSpinUp()
            if CUSTOM_USE_PID:
                await asyncio.sleep(SPOOL_S)
            await moveAim(jh.customCowl, jh.customTurret, doFeed=True)
            customSpinDown()
            jh.testShotActive = False
        if jh.liveAim:
            await moveAim(jh.customCowl, jh.customTurret)
    
    
feedStartDelay = 1   # seconds; 0 = feed after aiming finishes

COWL_MAX = 25

def killWheels():
    setWheelRPM(0)
    shooterLower.rampDown(0, 1000, 0.05)
    shooterUpper.rampDown(0, 1000, 0.05)

async def moveAim(cowl, turret, doFeed=False):
    global cowlAngle, turretAngle
    cowl = max(0, min(COWL_MAX, cowl))
    jobs = []
    if cowlAngle != cowl:
        cowlMotor.prepare(abs(cowl - cowlAngle), 200, 0 if cowl > cowlAngle else 1)
        jobs.append(cowlMotor)
        cowlAngle = cowl
    if turretAngle != turret:
        turretMotor.prepare(abs(turret - turretAngle), 500, 0 if turret > turretAngle else 1)
        jobs.append(turretMotor)
        turretAngle = turret
    if not jobs and not doFeed:
        return
    if doFeed:
        print("we shootin fr fr")
        feederMotor.enable()
    started = jh.isRunning
    await motors.moveTogether(jobs, feederMotor if doFeed else None, feedStartDelay,
                              lambda: started and not jh.isRunning, killWheels)
    feederMotor.disable()
    turretMotor.disable()
    if cowlAngle == 0:
        cowlMotor.disable()
        

cycleCount = 0
randShots = 0
shotCount0 = 0
seqS = 10
seqT = 0
seqC = 0
seqP = 0
seqF = 7
up = True

async def seq():
    global isRunning0, timer, shotCount, cycleCount, up, shotCount0, randShots  # CHANGED (added randShots)
    isRunning = jh.isRunning
    numCycles = jh.numCycles
    savedCustoms = jh.savedCustoms
    sequence = jh.sequence

    rand = jh.sequenceDirection == "random"                                      # NEW
    if rand and sequence and jh.isRunning and not isRunning0:                    # NEW
        shotCount = random.randrange(len(sequence))                              # NEW
        shotCount0 = shotCount                                                   # NEW
        randShots = 0                                                            # NEW

    if savedCustoms == [] or sequence == []:
        return
    custom = []
    for c in savedCustoms:
        if c[0] == sequence[shotCount]:
            custom = c
            break
    if custom == []:
        return

    seqS = custom[1]
    seqT = custom[2]
    seqC = custom[3]
    seqP = custom[4]
    seqF = jh.gFreq if jh.timing == "global" else custom[5]

    if isRunning and not isRunning0:
        shooterUpper.rampUp(seqS*220+5800, step=1000)
        shooterLower.rampUp(seqS*220+5800-(seqP*100), step=1000)
        timer = time.time_ns()
        if not rand:                                                             # CHANGED (step 4)
            shotCount = 0
        cycleCount = 0
    elif not isRunning and isRunning0:
        shooterLower.rampDown(0, 1000, 0.05)
        shooterUpper.rampDown(0, 1000, 0.05)
    isRunning0 = isRunning

    if isRunning:
        if shotCount != shotCount0:
            shooterUpper.rampDown(seqS*220+5800, 1000, 0.05)
            shooterLower.rampDown(seqS*220+5800 - (seqP*100), 1000, 0.05)
            shooterUpper.rampUp(seqS*220+5800, 1000, 0.05)
            shooterLower.rampUp(seqS*220+5800 - (seqP*100), 1000, 0.05)
            shotCount0 = shotCount
        if time.time_ns() - timer > seqF*1000000000:
            timer = 0
        if timer != 0:
            await moveAim(seqC, seqT)
        if timer == 0:
            await moveAim(seqC, seqT, doFeed=True)
            timer = time.time_ns()
            if rand:                                                             # CHANGED (step 5)
                randShots += 1
                shotCount = random.randrange(len(sequence))
                if numCycles != 10 and randShots >= numCycles * len(sequence):
                    randShots = 0
                    isRunning = False
                    jh.isRunning = False
            elif jh.sequenceDirection != "topToBottom":                          # CHANGED (was "if")
                if shotCount == (len(sequence) - 1):
                    cycleCount += 1
                    shotCount = 0
                else:
                    shotCount += 1
                if numCycles != 10 and cycleCount >= numCycles:   # CHANGED
                    cycleCount = 0
                    isRunning = False
                    jh.isRunning = False
            else:
                if up:
                    if shotCount == (len(sequence) - 1):
                        cycleCount += 1
                        up = False
                    else:
                        shotCount += 1
                    if numCycles != 10 and cycleCount >= numCycles:   # CHANGED
                        cycleCount = 0
                        isRunning = False
                        jh.isRunning = False
                else:
                    if shotCount == 0:
                        cycleCount += 1
                        up = True
                    else:
                        shotCount -= 1
                    if numCycles != 10 and cycleCount >= numCycles:   # CHANGED
                        cycleCount = 0
                        isRunning = False
                        jh.isRunning = False
    else:
        await moveAim(0, 0)
        shotCount = 0
        cycleCount = 0


>>>>>>> Stashed changes
async def isConnected():
    await asyncio.sleep(0.02)
    return bt.connected

<<<<<<< Updated upstream
async def control():
    global isRunning0
=======
loopTime0 = time.time_ns()
rpm = 0
lowArray = []
hiArray = []
lowrpm = 0
hirpm = 0
lowOutput = 0
hiOutput = 0
timer2 = time.time_ns()

WHEEL_DIA = 4 * 0.0254   # m
EXIT_EFF = 1.0           # ball exit speed / wheel surface speed; calibrate
ADJ_STEP = 0.5           # m/s per SPEED ADJ step; tune

CUSTOM_USE_PID = True    # False = original rampUp behavior
MAX_EXIT_SPEED = 25.0    # m/s at slider 100%
SPIN_RPM_STEP = 100      # RPM difference per SPIN step
SPOOL_S = 2.0            # test shot: seconds to reach speed before feeding

targetUpper = 0          # RPM setpoints read by control()
targetLower = 0
gridShots = []
gridIdx = 0
gridUp = True

def speedToRPM(v):
    return (v / EXIT_EFF) * 60 / (math.pi * WHEEL_DIA)

def setWheelRPM(upper, lower=None):
    global targetUpper, targetLower
    targetUpper = upper
    targetLower = upper if lower is None else lower
    
def customSpinUp():
    if CUSTOM_USE_PID:
        up = speedToRPM(jh.customSpeed / 100 * MAX_EXIT_SPEED)
        setWheelRPM(up, max(up - jh.customSpin * SPIN_RPM_STEP, 0))
    else:
        shooterUpper.rampUp(jh.customSpeed*220+5800, step=1000)
        shooterLower.rampUp(jh.customSpeed*220+5800-(jh.customSpin*100), step=1000)

def customSpinDown():
    setWheelRPM(0)
    shooterLower.rampDown(0, 1000, 0.05)
    shooterUpper.rampDown(0, 1000, 0.05)

def updateRPM():
    global rpm, loopTime0, lowerCounter0, upperCounter0, lowrpm, hirpm
    loopTime = time.time_ns() - loopTime0
    loopTime0 = time.time_ns()
    rpm = (lowerCounter0 / (loopTime / 1000000000)) * 30
    lowArray.append(rpm)
    while len(lowArray) > 20:
        lowArray.pop(0)
    lowrpm = sum(lowArray) / len(lowArray)
    lowerCounter0 = 0

    rpm = (upperCounter0 / (loopTime / 1000000000)) * 30
    hiArray.append(rpm)
    while len(hiArray) > 20:
        hiArray.pop(0)
    hirpm = sum(hiArray) / len(hiArray)
    upperCounter0 = 0

def runPID():
    global lowOutput, hiOutput
    if targetUpper > 0:
        lowerPID.setpoint = targetLower
        lowOutput += lowerPID(lowrpm)
        shooterLower.shooterGo(lowOutput)

        upperPID.setpoint = targetUpper
        hiOutput += upperPID(hirpm)
        shooterUpper.shooterGo(hiOutput)
    else:
        lowOutput = 0
        hiOutput = 0
        

async def pidTask():
    global lowOutput, hiOutput
    while True:
        await asyncio.sleep(0.01)
        if not bt.connected:
            continue
        updateRPM()
        mode = jh.currentMode.split(".")[1]
        if mode in ("grid", "random") or (CUSTOM_USE_PID and mode == "custom"):
            runPID()
        else:
            lowOutput = 0
            hiOutput = 0


def buildShots(targets):
    shots = []
    for col, row in targets:
        try:
            ip.setInputs((jh.topCol, jh.topRow), (col, row), jh.power)
            res = ip.linearInterpolation()
            turret = ip.getTurretAngle()
        except IndexError:
            res = "Value out of range"
        if isinstance(res, str):
            print("Skipping out-of-range target", col, row)
            continue
        speed, angle = res
        if angle > COWL_MAX:
            print("Skipping target", col, row, "needs cowl", angle)
            continue
        speed += jh.speedAdjustment * ADJ_STEP
        shots.append((speedToRPM(speed), turret, angle))   # (rpm, turret, cowl)
    return shots

def nextIndex(i, n, rand):
    global gridUp
    if rand:
        return random.randrange(n)
    if jh.pattern == "1-8|1-8":
        return (i + 1) % n
    if gridUp:
        if i == n - 1:
            gridUp = False
            return i
        return i + 1
    if i == 0:
        gridUp = True
        return i
    return i - 1

async def gridRandom(rand):
    global isRunning0, timer, shotCount, gridShots, gridIdx, gridUp
    isRunning = jh.isRunning

    if isRunning and not isRunning0:
        gridShots = buildShots(jh.randomBottomSelection if rand else jh.gridSel)
        if not gridShots:
            jh.isRunning = False
            return
        gridIdx = random.randrange(len(gridShots)) if rand else 0
        gridUp = True
        shotCount = 0
        setWheelRPM(gridShots[gridIdx][0])
        timer = time.time_ns()
    elif not isRunning and isRunning0:
        setWheelRPM(0)
        shooterLower.rampDown(0, 1000, 0.05)
        shooterUpper.rampDown(0, 1000, 0.05)
    isRunning0 = isRunning

    if isRunning:
        _, turret, cowl = gridShots[gridIdx]
        if time.time_ns() - timer > jh.freq * 1000000000:
            timer = 0
        if timer != 0:
            await moveAim(cowl, turret)
        else:
            await moveAim(cowl, turret, doFeed=True)
            if not jh.isRunning:
                return
            timer = time.time_ns()
            shotCount += 1
            if jh.numBalls != 25 and shotCount >= jh.numBalls:
                jh.isRunning = False
            else:
                gridIdx = nextIndex(gridIdx, len(gridShots), rand)
                setWheelRPM(gridShots[gridIdx][0])
    else:
        await moveAim(0, 0)

async def control():
    global isRunning0, lowerValue0, upperValue0, rpm, lowerPulse0, upperPulse0, loopTime0, lowerCounter0, upperCounter0, lowrpm, hirpm, lowOutput, hiOutput, timer2, targetUpper, targetLower
>>>>>>> Stashed changes
    while True:
        connected = await isConnected()
        if connected:
            appMode = jh.currentMode
            x, mode = appMode.split(".")

            if DEBUG_RPM and time.time_ns() - timer2 > 500000000:
                print(lowrpm, hirpm)
                timer2 = time.time_ns()

            if mode == "grid":
<<<<<<< Updated upstream
                await grid()
=======
                await gridRandom(False)
            if mode == "random":
                await gridRandom(True)
>>>>>>> Stashed changes
            if mode == "custom":
                await custom()
            if mode == "seq":
<<<<<<< Updated upstream
                1==1
            if mode == "debug":
                1==1
            if mode == "settings":
                1==1
=======
                await seq()
        else:
            targetUpper = 0
            targetLower = 0
            shooterLower.rampDown(0, 1000, 0.05)
            shooterUpper.rampDown(0, 1000, 0.05)
>>>>>>> Stashed changes


async def main():
    await asyncio.gather(
        control(),
        bt.advertise(),
        bt.json_task(),
    )
    
asyncio.run(main())