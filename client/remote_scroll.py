import ConfigParser
import os
import re
import sys
import time, random
import json
from uuid import getnode

from api_util import HOST, PORT
import requests

ID = getnode()/100000


# DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}
DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'MyFancyNetwork', 'bssid': '0:b:86:74:9a:98'}

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

ID = random.randrange(0, 10000)

broadcast_id = requests.post(url='http://%s:%d/broadcasts/' % (HOST, PORT), headers={'content-type': 'application/json'}, data=json.dumps({'remote_id': ID, 'connected': DUMMY_CONNECTED})).json()['broadcast_id']
print 'have broadcast with id', broadcast_id

screen_id = int(sys.argv[1])

r = requests.post('http://%s:%d/broadcasts/%s/screens/' % (HOST, PORT, broadcast_id), data={'screen_id': screen_id})
if r.status_code != 200:
    print 'failed to add %s to broadcast %s' % (screen_id, broadcast_id)
    exit(1)

print 'added screen %s to broadcast %s' % (screen_id, broadcast_id)
time.sleep(1.0)

# do loop here
if True:
    first_url = sys.argv[2] if len(sys.argv) >= 3 else None
    while True:
        url = first_url if first_url else raw_input('Enter URL, "q" to quit, u/d to scroll, n/p to slide, blank for xkcd: ')
        first_url = None
        if url == 'q':
            break
        elif url == '':
            url = 'http://www.xkcd.com'
        if url == 'u':
            data = dict(type='vscroll', value=float(-0.5))
        elif url == 'd':
            data = dict(type='vscroll', value=float(0.5))
        elif url == 'n' or url == 'p':
            print "slide!"
            data = dict(type='slide', value=url)
        else:
            data = dict(type='url', url=url)
	r = requests.post('http://%s:%d/broadcasts/%s/' % (HOST, PORT, broadcast_id),
                      headers={'content-type':'application/json'},
                      data=json.dumps(data))
        print 'pushed %s to broadcast %s' % (url, broadcast_id)
