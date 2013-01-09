import sys
import time
import json

import requests

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

screen_id = int(sys.argv[1])
broadcast_id = requests.post(url='http://127.0.0.1:5000/broadcasts/').json()
print 'have broadcast with id', broadcast_id
r = requests.post('http://127.0.0.1:5000/broadcasts/%s/screens/' % broadcast_id, data={'screen_id': screen_id})
if r.status_code != 200:
    print 'failed to add %s to broadcast %s' % (screen_id, broadcast_id)
    exit(1)

print 'added screen %s to broadcast %s' % (screen_id, broadcast_id)
time.sleep(1.0)
r = requests.post('http://127.0.0.1:5000/broadcasts/%s/' % broadcast_id, data={'data': url})
print 'pushed %s to broadcast %s' % (url, broadcast_id)
