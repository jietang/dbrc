from api_util import request, HOST, PORT
import json
import webbrowser
import time
import requests

ID=1

r = requests.post('http://%s:%d/screens/' % (HOST, PORT), data={'device_id': ID})
screen_id = r.json()["screen_id"]
print "current screen id: ", screen_id

while True:
    try:
        print 'subscribing as screen %s...' % (screen_id,)
        resp = request('screens/%s' % (screen_id,))
    except Exception:
        time.sleep(1)
        continue

    if resp['result'] == 'resubscribe':
        print "resubscribing"
        continue
    elif resp['result'] == 'ok':
        print "Launching: ", json.loads(resp['data'])
        webbrowser.open(json.loads(resp['data']))
        continue
