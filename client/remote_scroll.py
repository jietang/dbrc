import sys
import time
import json
import random

from api_util import HOST, PORT
import requests

DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}
# DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'MyFancyNetwork', 'bssid': '0:b:86:74:9a:98'}

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

ID = random.randrange(0, 10000)

broadcast_id = requests.post(url='http://%s:%d/broadcasts/' % (HOST, PORT), headers={'content-type': 'application/json'}, data=json.dumps({'remote_id': ID, 'connected': DUMMY_CONNECTED})).json()['broadcast_id']
print 'have broadcast with id', broadcast_id

#likely_screens = requests.get(url='http://%s:%d/broadcasts/%s/likely_screens/' % (HOST, PORT, broadcast_id)).json()

#for i, entry in enumerate(likely_screens):
#    print "%d) %s" % (i+1, entry['device_name'])

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
        url = first_url if first_url else raw_input('Enter URL, "q" to quit, "d"/"u" to scroll, blank for xkcd: ')
        first_url = None
        if url == 'q':
            break
        elif url == '':
            url = 'http://www.xkcd.com'
        if url in ['u', 'd']:
            r = requests.post('http://%s:%d/broadcasts/%s/' % (HOST, PORT, broadcast_id), data={'data': json.dumps(dict(action=url))})
        else:
            r = requests.post('http://%s:%d/broadcasts/%s/' % (HOST, PORT, broadcast_id), data={'data': json.dumps(dict(url=url))})
        print 'pushed %s to broadcast %s' % (url, broadcast_id)
"""
    kMPOAuthCredentialAccessToken = cukdmaxz99ftvqi;
    kMPOAuthCredentialAccessTokenSecret = 73wowjpmc7x0703;
    kMPOAuthCredentialConsumerKey = gafchy215r87od1;
    kMPOAuthCredentialConsumerSecret = 0bhl35g2fcybyvh;
    kMPOAuthSignatureMethod = PLAINTEXT;
}
initWithAppKey:@"gafchy215r87od1"
appSecret:@"0bhl35g2fcybyvh"
"""
