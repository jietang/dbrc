import sys
import time
import json

from api_util import HOST, PORT
import requests

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

screen_id = int(sys.argv[1])
broadcast_id = requests.post(url='http://%s:%d/broadcasts/' % (HOST, PORT)).json()['broadcast_id']
print 'have broadcast with id', broadcast_id
r = requests.post('http://%s:%d/broadcasts/%s/screens/' % (HOST, PORT, broadcast_id), data={'screen_id': screen_id})
if r.status_code != 200:
    print 'failed to add %s to broadcast %s' % (screen_id, broadcast_id)
    exit(1)

print 'added screen %s to broadcast %s' % (screen_id, broadcast_id)
time.sleep(1.0)
r = requests.post('http://%s:%d/broadcasts/%s/' % (HOST, PORT, broadcast_id), data={'data': json.dumps(url)})
print 'pushed %s to broadcast %s' % (url, broadcast_id)
