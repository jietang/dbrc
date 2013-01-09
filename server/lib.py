from environment import redis_session as _r
import random
import Queue
import uuid
from threading import Thread

def blocking_listen(channel, timeout=None):
    #TODO: timeouts are kinda tricky
    assert timeout < 60 * 5, 'maximum 5 minute timeout'
    myq = Queue.Queue()
    kill_channel = '%s' % uuid.uuid4()
    def wait_thing(timeout):
        if not timeout:
            return
        else:
            time.sleep(timeout)
            myq.put('END')
    def get_signal():
        p = _r.pubsub()
        p.subscribe(channel)
        p.subscribe(kill_channel)
        for m in p.listen():
            if m['type'] == 'message':
                myq.put(m['data'])
                return
    Thread(target=wait_thing).start()
    Thread(target=get_signal).start()
    to_ret = myq.get()
    if to_ret == 'END':
        _r.publish(kill_channel, '')
        return {"error_message": "request timed out"}
    else:
        return to_ret


def generate_random_id():
    n = _r.get('id_sample_range')
    while True:
        candidate_id = random.randrange(0, n, 1)
        if (not _r.get('screen_info_%s' % candidate_id) and
            not _r.get('broadcast_info_%s' % candidate_id)):
            return candidate_id
        n *= 10
        _r.set('id_sample_range', n)
