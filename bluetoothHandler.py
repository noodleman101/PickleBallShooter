import bluetooth
import aioble
import ujson
import jsonHandler as jh

# UUIDs (must match Flutter)
SERVICE_UUID = bluetooth.UUID("fe1dcbe3-4f5e-4e98-bcaf-8ab7731a731a")
CHAR_UUID = bluetooth.UUID("fe1dcbe3-4f5e-4e98-bcaf-8ab7731a731b")
service = aioble.Service(SERVICE_UUID)
json_char = aioble.Characteristic( service, CHAR_UUID, write=True, )

connected = False

aioble.register_services(service)
buffer = ""

async def json_task():
    global buffer
    print("JSON task started, waiting for writes...")
    while True:
        await json_char.written()
        raw = json_char.read()
        buffer += raw.decode()
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            try:
                obj = ujson.loads(line)
                jh.handle_json(obj)
            except Exception as e:
                print("JSON error:", e, line)

    
async def advertise():
    global connected
    while True:
        #lcd.clear()
        #lcd.putstr("Advertising...")
        print("Advertising as pico...")
        connection = await aioble.advertise(
            interval_us=50_000,
            name="PICO_LED",
            services=[SERVICE_UUID],
            appearance=0x0000, # Generic
            connectable=True,
        )
        
        print("Central connected:", connection.device)
        #lcd.clear()
        #lcd.putstr("Connected")
        connected = True
        
        await connection.disconnected()
        print("Central disconnected")
        #lcd.clear()
        #lcd.putstr("Disconnected")
        connected = False