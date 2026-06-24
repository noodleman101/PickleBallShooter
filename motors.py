from machine import Pin, PWM
import time

class ShooterMotor:
    def __init__(self, shooterPWM, shooterEN=None, freq=20000):
        self.shooterPWM = PWM(Pin(shooterPWM))
        self.shooterPWM.freq(freq)

        self.shooterEN = Pin(shooterEN, Pin.OUT) if shooterEN is not None else None

        self.shooterStop()
        self.shooterDisable()
        self.speed = 0

    def shooterEnable(self):
        if self.shooterEN:
            self.shooterEN.value(1)

    def shooterDisable(self):
        if self.shooterEN:
            self.shooterEN.value(0)

    def shooterGo(self, speed):
        self.shooterEnable()
        self.shooterPWM.duty_u16(int(speed))
        self.speed = 0

    def shooterStop(self):
        self.shooterPWM.duty_u16(0)

    def rampUp(self, targetSpeed, step=1000, speedUpDelay=0.05):
        speed = self.shooterPWM.duty_u16()
        if speed > targetSpeed:
            return
        self.shooterEnable()
        while speed < targetSpeed:
            self.shooterGo(speed)
            speed += step
            if speed > targetSpeed:
                speed = targetSpeed
            time.sleep(speedUpDelay)
        self.shooterGo(targetSpeed)

    def rampDown(self, targetSpeed, step=1000, speedDownDelay=0.05):
        speed = self.shooterPWM.duty_u16()
        if speed < targetSpeed:
            return
        while speed > targetSpeed:
            self.shooterGo(speed)
            speed -= step
            if speed < targetSpeed:
                speed = targetSpeed
            time.sleep(speedDownDelay)
        if targetSpeed == 0:
            self.shooterStop()
            self.shooterDisable()
        else:
            self.shooterGo(targetSpeed)
        
class Stepper:
    def __init__ (self, STEPPin, DIRPin, ENPin, ratio):
        self.STEP = Pin(STEPPin, Pin.OUT)
        self.DIR = Pin(DIRPin, Pin.OUT)
        self.EN = Pin(ENPin, Pin.OUT)
        self.ratio = ratio
        
        self.EN.value(1) #disabled to start
        
    def enable (self):
        self.EN.value(0)
        
    def disable (self):
        self.EN.value(1)
        
    def move (self,degrees,speedDelay,direction):
        self.EN.value(0)
        self.DIR.value(direction)
        steps = round((degrees * self.ratio) / (1.8/16))
        for _ in range(steps):
            self.STEP.value(1)
            time.sleep_us(2)      # min 1 µs
            self.STEP.value(0)
            time.sleep_us(speedDelay)