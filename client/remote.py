import ConfigParser
import os
import sys
import time
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


broadcast_id = requests.post(url='http://%s:%d/broadcasts/' % (HOST, PORT), headers={'content-type': 'application/json'}, data=json.dumps({'remote_id': ID, 'connected': DUMMY_CONNECTED})).json()['broadcast_id']
print 'have broadcast with id', broadcast_id


screen_id = None
while True:
    print "querying for known screens: "
    likely_screens = requests.get(url='http://%s:%d/broadcasts/%s/known_screens/' % (HOST, PORT, broadcast_id)).json()

    for i, entry in enumerate(likely_screens):
        print "%d) %s %s" % (i+1, entry['device_name'], 'P' if entry['known'] else '')

    inp = raw_input('Link with one of these (number to link, d<number> to delete, or "" to skip)? ')
    if inp and inp[0] == 'd':
        # make delete call
        r = requests.delete('http://%s:%d/broadcasts/%s/screens/%s' % (HOST, PORT, broadcast_id, likely_screens[int(inp[1:])-1]['screen_id']))
        continue
    else:
        if inp == "":
            screen_id = raw_input('Enter screen id: ')
        else:
            screen_id = likely_screens[int(inp)-1]['screen_id']
        break

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
        config = ConfigParser.ConfigParser()
        config.read(os.path.expanduser('~/.dbrc_config'))

        APP_KEY = config.get('secrets','app_key')
        APP_SECRET = config.get('secrets','app_secret')
        ACCESS_TOKEN = config.get('secrets','access_token')
        ACCESS_TOKEN_SECRET = config.get('secrets','access_token_secret')
        
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
