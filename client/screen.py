from api_util import request, HOST, PORT
import json
import webbrowser
import time
import requests
import tempfile

from uuid import getnode

ID = getnode()/100000


DUMMY_CONNECTED = {'strength': '-59', 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}

DUMMY_SSIDS = [{'strength': -82, 'ssid': 'GreeMobile', 'bssid': '88:75:56:1:e7:2d'}, {'strength': -67, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:82'}, {'strength': -60, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:62'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:80'}, {'strength': -59, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:60'}, {'strength': -73, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:92'}, {'strength': -82, 'ssid': 'GreeGuest', 'bssid': '88:75:56:1:e7:2e'}, {'strength': -72, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:90'}, {'strength': -66, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:b0'}, {'strength': -64, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:b2'}, {'strength': -83, 'ssid': 'GreeCorp', 'bssid': '88:75:56:1:e7:2f'}, {'strength': -75, 'ssid': 'GreeMobile', 'bssid': '88:75:56:1:e7:22'}, {'strength': -73, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:96:80'}, {'strength': -68, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:96:8a'}, {'strength': -67, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:96:88'}, {'strength': -69, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:95:ea'}, {'strength': -70, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:95:e8'}, {'strength': -63, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:97:6a'}, {'strength': -63, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:97:68'}, {'strength': -88, 'ssid': 'GreeMobile', 'bssid': '88:75:56:15:25:9d'}, {'strength': -83, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:aa'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:a8'}, {'strength': -66, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:88'}, {'strength': -64, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:99:b8'}, {'strength': -65, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:8a'}, {'strength': -61, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:99:ba'}, {'strength': -84, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:95:aa'}, {'strength': -85, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:95:a8'}, {'strength': -85, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:90:fa'}, {'strength': -86, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:90:f8'}, {'strength': -56, 'ssid': 'DropboxGuest2.0', 'bssid': '0:b:86:74:9a:9a'}, {'strength': -56, 'ssid': 'Dropbox', 'bssid': '0:b:86:74:9a:98'}]

PAGE = '''
<html>
<head>
  <style>
    .slideshow {
      width: 100%%;
      background-color: #000;
      display: none;
    }
    .slideshow img {
      margin: 0 auto;
      padding: 15px;
      border: 1px solid #ccc;
      background-color: #eee;
    }

    #error {
      color: #f00;
    }
    #device_id, #screen_id, #url {
      font-weight: bold;
    }
    #container {
      margin: 15px auto;
      width: 1024px;
    }
    #content-div {
      border: 2px solid #8c8c8c;
      border-radius: 18px;
      overflow: hidden;
    }
    #cheeky {
        height: 54px;
        overflow: hidden;
        margin-left: -31px;
    }
    h1 {
      margin: 0px;
    }
    body {
        font-family: sans-serif;
      background: #cccccf;
      color: #333;
            width: 100%%;
    }
    #logo {
      display: inline-block;
    }
    #header {
      width: 1024px;
    }
    .dbrc-info {
        display: inline-block; 
        float: right;
    }
    .info {
      padding: 5px;
    }
  </style>
</head>

<body>
  <div id='container'>
    <div id="header">
      <div id="logo">
        <div id="cheeky"><img src="http://openiconlibrary.sourceforge.net/gallery2/open_icon_library-full/icons/png/128x128/others/animals-giraffe.png">
        </div>
        <h1>DBRC Screen</h1>
      </div>
      <div class="dbrc-info">
        <div>
          <div class="info" style="display: none">
            <span class="info-label">Dropcast URL:</span>
            <span id="url">[None]</span>
          </div>
        </div>
      </div>
    </div>

    <div id="content-div" style="width:100%%">
    <div style="margin: 0px auto;">
      <img style="width:1024px; height: auto;" src="%s"/>
    </div>
    </div>
  </div>
</body>
</html>
'''

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
    elif resp['result'] == 'ok':
        if json.loads(resp['data'])['type'] == 'url':
            myraw = PAGE % json.loads(resp['data'])['url']
            f = tempfile.NamedTemporaryFile()
            f.write(myraw)
            name = f.name
            f.file.flush()
            print "Launching: ", json.loads(resp['data'])['url']
            print "from:", name
            webbrowser.open('file://%s' % (name,))
            with open(name, 'r') as g:
              print g.read()
            import time
            time.sleep(1)
            f.close()
