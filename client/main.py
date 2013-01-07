import requests

HOST='127.0.0.1'
PORT=5000
ID=1

while True:
    r = requests.get('http://%s:%d/subscribe/%d' % (HOST, PORT, ID))
    print r.status_code, r.headers, r.encoding
    resp = r.json()
    if resp['result'] == 'resubscribe':
        print "resubscribing"
        continue
    elif resp['result'] == 'ok':
        print "Launching: ", resp['data']
        break
