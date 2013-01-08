from api_util import request
ID=1

screen_id = request('register', ID)['screen_id']
print "current screen id: ", screen_id

while True:
    resp = request('subscribe', screen_id)
    if resp['result'] == 'resubscribe':
        print "resubscribing"
        continue
    elif resp['result'] == 'ok':
        print "Launching: ", resp['data']
        break
