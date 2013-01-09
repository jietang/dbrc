from api_util import request, HOST, PORT
import json
import webbrowser
import time
import requests

ID=1

DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}

DUMMY_SSIDS = [{'strength': -82, 'ssid': 'GreeMobile', 'bssid': '88:75:56:1:e7:2d'}, {'strength': -67, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:82'}, {'strength': -60, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:62'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:80'}, {'strength': -59, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:60'}, {'strength': -73, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:92'}, {'strength': -82, 'ssid': 'GreeGuest', 'bssid': '88:75:56:1:e7:2e'}, {'strength': -72, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:90'}, {'strength': -66, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:b0'}, {'strength': -64, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:b2'}, {'strength': -83, 'ssid': 'GreeCorp', 'bssid': '88:75:56:1:e7:2f'}, {'strength': -75, 'ssid': 'GreeMobile', 'bssid': '88:75:56:1:e7:22'}, {'strength': -73, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:96:80'}, {'strength': -68, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:96:8a'}, {'strength': -67, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:96:88'}, {'strength': -69, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:95:ea'}, {'strength': -70, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:95:e8'}, {'strength': -63, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:6a'}, {'strength': -63, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:68'}, {'strength': -88, 'ssid': 'GreeMobile', 'bssid': '88:75:56:15:25:9d'}, {'strength': -83, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:aa'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:a8'}, {'strength': -66, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:88'}, {'strength': -64, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:b8'}, {'strength': -65, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:8a'}, {'strength': -61, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:ba'}, {'strength': -84, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:95:aa'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:95:a8'}, {'strength': -85, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:90:fa'}, {'strength': -86, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:90:f8'}, {'strength': -56, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:9a'}, {'strength': -56, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}]

# add a 'application/json' content-type header
r = requests.post('http://%s:%d/screens/' % (HOST, PORT),
                  headers={'content-type': 'application/json'},
                  data=json.dumps({
                      'device_id': ID,
                      'device_name': 'device_%d' % ID,
                      'pairing_info': {
                          'connected': DUMMY_CONNECTED,
                          'nearby': DUMMY_SSIDS,
                          }})
    )
screen_id = r.json()["screen_id"]
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
        print "Launching: ", json.loads(resp['data'])['url']
        webbrowser.open(json.loads(resp['data'])['url'])
        continue
