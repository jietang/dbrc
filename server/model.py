from middleware import redis_session as _r

import random

def register_device(device_id, screen_id):
    _r.set('device_to_screen_id_%s' % device_id, screen_id)
    _r.set('screen_to_device_id_%s' % screen_id, device_id)
    return screen_id

def get_screen_id(screen_id):
    return _r.get('device_to_screen_id_%s' % device_id)

def screen_listen():

def start_broadcast():
    _r.set('broadcast_info_%s' % broadcast_id, {"init_time": time.time()})
    return broadcast_id

def add_to_broadcast(screen_id, broadcast_id):
    _r.get

def remove_from_broadcast(screen_id, broadcast_id)
