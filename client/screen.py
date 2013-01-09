from api_util import request
import webbrowser
import time
import requests

ID=1

screen_id = requests.post('http://127.0.0.1:5000/screens/').json()['screen_id']
print "current screen id: ", screen_id

while True:
    try:
        print 'subscribing as screen %s...' % (screen_id,)
        resp = requests.get('http://127.0.0.1:5000/screens/%s' % (screen_id,))
    except Exception:
        time.sleep(1)
        continue

    if resp.json()['result'] == 'resubscribe':
        print "resubscribing"
        continue
    elif resp.json()['result'] == 'ok':
        print "Launching: ", resp.json()['data']['url']
        webbrowser.open(resp.json()['data']['url'])
        continue
