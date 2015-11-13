from json import JSONEncoder
import datetime
import random
import time
import sys

while True:
    timestamp = datetime.datetime.utcnow()
    energy = random.randint(23, 26)

    jsonString = JSONEncoder().encode({
        "timestamp": unicode(timestamp),
        "start": unicode(timestamp),
        "end": unicode(timestamp),
        "energy": energy,
        "energyCumul": 150,
        "powerMax": 30,
        "powerMin": 20
    })
    print jsonString
    sys.stdout.flush()
    time.sleep(random.randint(3,10))
