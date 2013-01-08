import sys
import time

from api_util import request

url = 'http://www.xkcd.com'
if len(sys.argv) > 2:
    url = sys.argv[2]

broadcast_id = request('create_broadcast')['broadcast_id']
request('add_to_broadcast', broadcast_id, int(sys.argv[1]))
time.sleep(1.0)
request('push', broadcast_id, url)
