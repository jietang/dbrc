import ConfigParser
import os
import sys
import time
import json
import random

from api_util import HOST, PORT
import requests


config = ConfigParser.ConfigParser()
config.read(os.path.expanduser('~/.dbrc_config'))

APP_KEY = config.get('secrets','app_key')
APP_SECRET = config.get('secrets','app_secret')
ACCESS_TOKEN = config.get('secrets','access_token')
ACCESS_TOKEN_SECRET = config.get('secrets','access_token_secret')



DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}
# DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'MyFancyNetwork', 'bssid': '0:b:86:74:9a:98'}

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

ID = random.randrange(0, 10000)

broadcast_id = requests.post(url='http://%s:%d/broadcasts/' % (HOST, PORT), headers={'content-type': 'application/json'}, data=json.dumps({'remote_id': ID, 'connected': DUMMY_CONNECTED})).json()['broadcast_id']
print 'have broadcast with id', broadcast_id

print "querying for likely screens: "
likely_screens = requests.get(url='http://%s:%d/broadcasts/%s/likely_screens/' % (HOST, PORT, broadcast_id)).json()

for i, entry in enumerate(likely_screens):
    print "%d) %s" % (i+1, entry['device_name'])

inp = raw_input('Link with one of these (number or "no")? ')
if inp == "no":
    screen_id = raw_input('Enter screen id: ')
else:
    screen_id = likely_screens[int(inp)-1]['screen_id']

r = requests.post('http://%s:%d/broadcasts/%s/screens/' % (HOST, PORT, broadcast_id), data={'screen_id': screen_id})
if r.status_code != 200:
    print 'failed to add %s to broadcast %s' % (screen_id, broadcast_id)
    exit(1)

print 'added screen %s to broadcast %s' % (screen_id, broadcast_id)
time.sleep(1.0)

# do loop here
while True:
    url = raw_input('URL to visit (q to quit, enter for xkcd, p for pair): ')
    if url == 'p':
        data = dict(type='pairing', app_key=APP_KEY,app_secret=APP_SECRET,access_token=ACCESS_TOKEN,access_token_secret=ACCESS_TOKEN_SECRET)
        print data
    else:
        if url == 'q':
            break
        elif url == '':
            url = 'http://www.xkcd.com'
        data = dict(type='url', url=url)
        
    r = requests.post('http://%s:%d/broadcasts/%s/' % (HOST, PORT, broadcast_id),
                      headers={'content-type':'application/json'},
                      data=json.dumps(data))
    print 'pushed %s to broadcast %s' % (url, broadcast_id)
