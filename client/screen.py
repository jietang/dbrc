from api_util import request
import webbrowser
import time

ID=1

screen_id = request('screens', ID)['screen_id']
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
        print "Launching: ", resp['data']['url']
        webbrowser.open(resp['data']['url'])
        continue
