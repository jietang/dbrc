from api_util import request
import webbrowser
import time

ID=1

screen_id = request('register', ID)['screen_id']
print "current screen id: ", screen_id

while True:
    try:
        resp = request('subscribe', screen_id)
    except Exception:
        time.sleep(1)
        continue

    if resp['result'] == 'resubscribe':
        print "resubscribing"
        continue
    elif resp['result'] == 'ok':
        print "Launching: ", resp['data']
        webbrowser.open(resp['data'])
        continue
