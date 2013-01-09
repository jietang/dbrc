from environment import redis_session as _r
from lib import blocking_listen

import time


## SCREEN ##

def register_device(device_id, screen_id):
    _r.set('device_to_screen_id_%s' % device_id, screen_id)
    _r.set('screen_to_device_id_%s' % screen_id, device_id)
    _r.set('screen_info_%s' % screen_id,
           {"init_time": time.time(), "broadcasts": {}})
    return screen_id

def get_screen_id(device_id):
    return _r.get('device_to_screen_id_%s' % device_id)

def screen_listen(screen_id):
    return blocking_listen('screen_channel_%s' % screen_id, 2)

def get_screen(screen_id):
    return _r.get('screen_info_%s' % screen_id)

## BROADCAST ##

def start_broadcast(broadcast_id):
    _r.set('broadcast_info_%s' % broadcast_id,
           {"init_time": time.time(), "screens": {}})
    return broadcast_id

def get_broadcast(broadcast_id):
    return _r.get('broadcast_info_%s' % broadcast_id)

def publish(broadcast_id, data):
    broadcast_info = get_broadcast(broadcast_id)
    for screen_id in broadcast_info['screens']:
        _r.publish('screen_channel_%s' % screen_id, data)

## SUBSCRIPTION ##
def add_to_broadcast(screen_id, broadcast_id):
    broadcast_info = _r.get('broadcast_info_%s' % broadcast_id)
    screen_info = _r.get('screen_info_%s' % screen_id)
    start_time = time.time()

    broadcast_info['screens'][screen_id] = start_time
    screen_info['broadcasts'][broadcast_id] = start_time

    _r.set('screen_info_%s' % screen_id, screen_info)
    return _r.set('broadcast_info_%s' % broadcast_id, broadcast_info)

def remove_from_broadcast(screen_id, broadcast_id):
    broadcast_info = _r.get('broadcast_info_%s' % broadcast_id)
    screen_info = _r.get('screen_info_%s' % screen_id)

    broadcast_info['screens'].pop(screen_id)
    screen_info['broadcasts'].pop(broadcast_id)

    _r.set('screen_info_%s' % screen_id, screen_info)
    return _r.set('broadcast_info_%s' % broadcast_id, broadcast_info)
