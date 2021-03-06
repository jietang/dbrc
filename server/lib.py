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
    current_queue = non_blocking_listen(channel)
    if current_queue:
        return {"result": "ok", "data": current_queue[-1]}
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
                myq.put(m['data'])
                return
    Thread(target=wait_thing, args=(timeout,)).start()
    Thread(target=get_signal).start()
    to_ret = myq.get()
    if to_ret == 'END':
        redis_session.publish(kill_channel, '')
        return {"result": "resubscribe", "screen_id": "1"}
    else:
        # pop off the element from the queue if we're about to send it down
        screen_queue = _rget("queue_%s" % channel) or []
        try:
            screen_queue.remove(to_ret)
        except ValueError:
            pass
        else:
            _rset('queue_%s' % channel, screen_queue)
        
        return {"result": "ok", "data": to_ret}


def non_blocking_listen(channel):
    myq = _rget("queue_%s" % channel) or []
    if myq:
        _rset("queue_%s" % channel, [])
    return myq

def generate_random_id():
    n = 9999
    for i in range(100000):
        candidate_id = random.randrange(1000, n, 1)
        if (not _rget('screen_info_%s' % candidate_id) and
            not _rget('broadcast_info_%s' % candidate_id)):
            return candidate_id

    return -1
