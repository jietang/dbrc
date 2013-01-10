from environment import redis_session
from threading import Thread
import Queue
import random
import json
import time
import uuid

def _rset(key, value):
    redis_session.set(key, json.dumps(value))

def _rget(key):
    to_ret = redis_session.get(key)
    if to_ret:
        return json.loads(to_ret)

def blocking_listen(channel, timeout=None):
    #TODO: timeouts are kinda tricky
    assert timeout < 60 * 5, 'maximum 5 minute timeout'
    current_queue = non_blocking_listen(channel):
    if current_queue:
        return current_queue[-1]
    myq = Queue.Queue()
    kill_channel = '%s' % uuid.uuid4()
    def wait_thing(timeout):
        if not timeout:
            return
        else:
            time.sleep(timeout)
            myq.put('END')
    def get_signal():
        p = redis_session.pubsub()
        p.subscribe(channel)
        p.subscribe(kill_channel)
        for m in p.listen():
            if m['type'] == 'message':
                myq.put(json.dumps(m['data']))
                return
    Thread(target=wait_thing, args=(timeout,)).start()
    Thread(target=get_signal).start()
    to_ret = myq.get()
    if to_ret == 'END':
        redis_session.publish(kill_channel, '')
        return {"result": "resubscribe", "screen_id": "1"}
    else:
        return {"result": "ok", "data": json.loads(to_ret)}


def non_blocking_listen(channel):
    myq = _rget("queue_%s" % channel) or []
    if myq:
        _rset("queue_%s" % channel)
    return myq

def generate_random_id():
    n = _rget('id_sample_range') or 10
    while True:
        candidate_id = random.randrange(0, n, 1)
        if (not _rget('screen_info_%s' % candidate_id) and
            not _rget('broadcast_info_%s' % candidate_id)):
            return candidate_id
        n *= 10
        _rset('id_sample_range', n)
