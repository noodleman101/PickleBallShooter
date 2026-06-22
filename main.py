import aioble
import asyncio
from machine import Pin,PWM
from micropython import const
import time
import jsonHandler as jh
import bluetoothHandler as bt
import motors
from picozero import pico_led

shooterLower = motors.ShooterMotor(shooterPWM = 27, shooterEN = 28)
shooterUpper = motors.ShooterMotor(shooterPWM = 22, shooterEN = 26)

feederMotor = motors.Stepper(16,17,15, 1)
feederMotor.disable()

cowlMotor = motors.Stepper(18,19,14, 3250/192)
cowlMotor.disable()
cowlAngle = 0

turretMotor = motors.Stepper(20,21,13,70/18)
turretMotor.disable()
turretAngle = 0
  
async def feed():
    print("we shootin fr fr")
    feederMotor.enable()
    feederMotor.move(180,500,0)
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
        shooterLower.rampDown(1000,0.05)
        shooterUpper.rampDown(1000,0.05)
    isRunning0 = isRunning
        
    if isRunning:
        if shotCount == jh.numBalls:
            jh.isRunning = False
            isRunning = False
        if timer == 0:
            await feed()
            timer = time.time_ns()
            shotCount = shotCount + 1
        if (time.time_ns() - timer > jh.customFreq*1000000000):
            timer = 0
            
            
    updateCowl(jh.customCowl)
    updateTurret(jh.customTurret)
    
    if testShotActive:
        await feed()
        jh.testShotActive = False
        
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
        turretMotor.move(abs(angle - turretAngle), 1000, 1 if angle > turretAngle else 0)
        turretAngle = angle
        turretMotor.disable()

cycleCount = 0
seqS = 10
seqT = 0
seqC = 0
seqP = 0
seqF = 7
async def seq():
    global isRunning0, timer, shotCount, cycleCount
    isRunning = jh.isRunning
    
    if jh.savedCustoms == []:
        return
    
    custom = jh.savedCustoms[jh.sequence[shotCount] - 1]
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
        shooterLower.rampDown(1000,0.05)
        shooterUpper.rampDown(1000,0.05)
    isRunning0 = isRunning
    
        
    updateCowl(seqC)
    updateTurret(seqT)
    
        
    
    if isRunning:
        1==1
    
    
 
async def isConnected():
    await asyncio.sleep(0.02)
    return bt.connected

async def control():
    global isRunning0
    while True:
        connected = await isConnected()
        if connected:
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


async def main():
    await asyncio.gather(
        control(),
        bt.advertise(),
        bt.json_task(),
    )
    
asyncio.run(main())
