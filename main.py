import aioble
import asyncio
from machine import Pin,PWM
from micropython import const
import time
import jsonHandler as jh
import bluetoothHandler as bt
import motors
from picozero import pico_led
from simple_pid import PID

lowerCounter0 = 0
def lowerCounter(pin):
    global lowerCounter0
    lowerCounter0 += 1
upperCounter0 = 0
def upperCounter(pin):
    global upperCounter0
    upperCounter0 += 1

shooterLower = motors.ShooterMotor(shooterPWM = 27, shooterEN = 28)
lowerPID = PID(0.015, 0, 0, setpoint=1)
lowerSensor = Pin(12, Pin.IN)
lowerSensor.irq(trigger=Pin.IRQ_FALLING, handler=lowerCounter)
shooterUpper = motors.ShooterMotor(shooterPWM = 22, shooterEN = 26)
upperPID = PID(0.015, 0, 0, setpoint=1)
upperSensor = Pin(11, Pin.IN)
upperSensor.irq(trigger=Pin.IRQ_FALLING, handler=upperCounter)



feederMotor = motors.Stepper(16,17,15, 14)
feederMotor.disable()

cowlMotor = motors.Stepper(18,19,14, 3250/192)
cowlMotor.disable()
cowlAngle = 0

turretMotor = motors.Stepper(20,21,13,70/8)
turretMotor.disable()
turretAngle = 0
  
async def feed():
    print("we shootin fr fr")
    feederMotor.enable()
    feederMotor.move(180,120,1)
    feederMotor.disable()
    
isRunning0 = False
timer = 0
shotCount = 0
async def custom():
    global isRunning0, cowlAngle, turretAngle, timer, shotCount
    customSpeed = jh.customSpeed
    customSpin = jh.customSpin
    isRunning = jh.isRunning
    testShotActive = jh.testShotActive
    
    if isRunning and not isRunning0:
        shooterUpper.rampUp(customSpeed*220+5800, step=1000)
        shooterLower.rampUp(customSpeed*220+5800-(customSpin*100), step=1000)
        timer = time.time_ns()
        shotCount = 0
    elif not isRunning and isRunning0:
        shooterLower.rampDown(0, 1000, 0.05)
        shooterUpper.rampDown(0, 1000, 0.05)
    isRunning0 = isRunning
        
    if isRunning:
        updateCowl(jh.customCowl)
        updateTurret(jh.customTurret)
        if shotCount == jh.numBalls:
            jh.isRunning = False
            isRunning = False
        if timer == 0:
            await feed()
            timer = time.time_ns()
            shotCount = shotCount + 1
        if (time.time_ns() - timer > jh.customFreq*1000000000):
            timer = 0
    else:
        if testShotActive:
            updateCowl(jh.customCowl)
            updateTurret(jh.customTurret)
            shooterUpper.rampUp(customSpeed*220+5800, step=1000)
            shooterLower.rampUp(customSpeed*220+5800-(customSpin*100), step=1000)
            await feed()
            shooterLower.rampDown(0, 1000, 0.05)
            shooterUpper.rampDown(0, 1000, 0.05)
            jh.testShotActive = False
        updateCowl(0)
        updateTurret(0)
    
    
        
def updateCowl(angle):
    global cowlAngle
    if cowlAngle != angle:
        cowlMotor.enable()
        cowlMotor.move(abs(angle - cowlAngle), 200, 0 if angle > cowlAngle else 1)
        cowlAngle = angle
        time.sleep(0.25)
        if cowlAngle == 0:
            cowlMotor.disable()
            
def updateTurret(angle):
    global turretAngle
    if turretAngle != angle:
        turretMotor.enable()
        turretMotor.move(abs(angle - turretAngle), 500, 0 if angle > turretAngle else 1)
        turretAngle = angle
        turretMotor.disable()

cycleCount = 0
shotCount0 = 0
seqS = 10
seqT = 0
seqC = 0
seqP = 0
seqF = 7
up = True
async def seq():
    global isRunning0, timer, shotCount, cycleCount, up, shotCount0
    isRunning = jh.isRunning
    numCycles = jh.numCycles
    savedCustoms = jh.savedCustoms
    sequence = jh.sequence
    
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
    seqF = custom[5]
    
    if isRunning and not isRunning0:
        shooterUpper.rampUp(seqS*220+5800, step=1000)
        shooterLower.rampUp(seqS*220+5800-(seqP*100), step=1000)
        timer = time.time_ns()
        shotCount = 0
        cycleCount = 0
    elif not isRunning and isRunning0:
        shooterLower.rampDown(0, 1000, 0.05)
        shooterUpper.rampDown(0, 1000,0.05)
    isRunning0 = isRunning    
    
    if isRunning:
        updateCowl(seqC)
        updateTurret(seqT)
        if shotCount != shotCount0:
            shooterUpper.rampDown(seqS*220+5800, 1000, 0.05)
            shooterLower.rampDown(seqS*220+5800 - (seqP*100), 1000, 0.05)
            shooterUpper.rampUp(seqS*220+5800, 1000, 0.05)
            shooterLower.rampUp(seqS*220+5800 - (seqP*100), 1000, 0.05)
            shotCount0 = shotCount
        if time.time_ns() - timer > seqF*1000000000:
            timer = 0
        if timer == 0:
            await feed()
            timer = time.time_ns()
            if jh.sequenceDirection != "topToBottom":
                if shotCount == (len(sequence) - 1):
                    # if we reached the end of the sequence, increase cycle and go back to 0 shots
                    cycleCount += 1
                    shotCount = 0
                else:
                    shotCount += 1
                if cycleCount == numCycles:
                    cycleCount = 0
                    isRunning = False
                    jh.isRunning = False
            else:
                #bottomToTop
                if up:
                    if shotCount == (len(sequence) - 1):
                        # if we reached the end of the sequence, increase cycle and stay at same shotcount
                        cycleCount += 1
                        up = False
                    else:
                        shotCount += 1
                    if cycleCount == numCycles:
                        cycleCount = 0
                        isRunning = False
                        jh.isRunning = False
                else:
                    if shotCount == 0:
                        # if we reached the end of the sequence, increase cycle and stay at 0 shots
                        cycleCount += 1
                        up = True
                    else:
                        shotCount -= 1
                    if cycleCount == numCycles:
                        cycleCount = 0
                        isRunning = False
                        jh.isRunning = False
                # end else
            # end else
        # end if
    else:
        updateCowl(0)
        updateTurret(0)
        shotCount = 0
        cycleCount = 0
    
    
 
async def isConnected():
    await asyncio.sleep(0.01)
    return bt.connected

loopTime0 = time.time_ns()
rpm = 0
lowArray = []
hiArray = []
lowrpm = 0
hirpm = 0
lowOutput = 0
hiOutput = 0
timer2 = time.time_ns()

async def control():
    global isRunning0, lowerValue0, upperValue0, rpm, lowerPulse0, upperPulse0, loopTime0, lowerCounter0, upperCounter0, lowrpm, hirpm, lowOutput, hiOutput, timer2
    while True:
        connected = await isConnected()
        if connected:
            
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
            
            lowerPID.setpoint = 3000
            lowOutput += lowerPID(lowrpm)
            shooterLower.shooterGo(lowOutput)
            
            upperPID.setpoint = 3000
            hiOutput += upperPID(hirpm)
            shooterUpper.shooterGo(hiOutput)
            
            if time.time_ns() - timer2 > 100000000:
                print(lowrpm)
                print(hirpm)
            
            
            appMode = jh.currentMode
            x, mode = appMode.split(".")
            if mode == "grid":
                1==1
            if mode == "custom":
                await custom()
            if mode == "random":
                1==1
            if mode == "seq":
                await seq()
            if mode == "debug":
                1==1
            if mode == "settings":
                1==1
        else:
            shooterLower.rampDown(0,1000,0.05)
            shooterUpper.rampDown(0,1000,0.05)


async def main():
    await asyncio.gather(
        control(),
        bt.advertise(),
        bt.json_task(),
    )
    
asyncio.run(main())
