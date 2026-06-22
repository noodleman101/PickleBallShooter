from machine import Pin, PWM
import time

class ShooterMotor:
    def __init__(self, shooterPWM, shooterEN=None, freq=20000):
        self.shooterPWM = PWM(Pin(shooterPWM))
        self.shooterPWM.freq(freq)

        self.shooterEN = Pin(shooterEN, Pin.OUT) if shooterEN is not None else None

        self.shooterStop()
        self.shooterDisable()

    def shooterEnable(self):
        if self.shooterEN:
            self.shooterEN.value(1)

    def shooterDisable(self):
        if self.shooterEN:
            self.shooterEN.value(0)

    def shooterGo(self, speed):
        self.shooterEnable()
        self.shooterPWM.duty_u16(int(speed))

    def shooterStop(self):
        self.shooterPWM.duty_u16(0)

    def rampUp(self, targetSpeed, step=1000, speedUpDelay=0.05):
        speed = 0
        self.shooterEnable()
        while speed < targetSpeed:
            self.shooterGo(speed)
            speed += step
            if speed > targetSpeed:
                speed = targetSpeed
            time.sleep(speedUpDelay)
        self.shooterGo(targetSpeed)

    def rampDown(self, step=1000, speedDownDelay=0.05):
        currentSpeed = self.shooterPWM.duty_u16()
        while currentSpeed > 0:
            self.shooterGo(currentSpeed)
            currentSpeed -= step
            if currentSpeed < 0:
                currentSpeed = 0
            time.sleep(speedDownDelay)
        self.shooterStop()
        self.shooterDisable()
        
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