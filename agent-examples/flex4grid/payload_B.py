from json import JSONEncoder
import datetime
import random
import time
import uuid
import sys

device_id = uuid.uuid4().urn[9:]

while True:
    timestamp = datetime.datetime.utcnow()

    jsonString = JSONEncoder().encode({
        "timestamp": unicode(int(time.time())),
        "id": device_id,
        "type": "ZWave smart plug",
        "status": "active"
    })
    print jsonString
    sys.stdout.flush()
    time.sleep(random.randint(10,10))
