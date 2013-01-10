from lib import blocking_listen, _rset, _rget
from environment import redis_session
import json
import time



## SCREEN ##
def get_all_device_ids():
    return redis_session.smembers('device_ids')

def get_all_remote_ids():
    return redis_session.smembers('remote_ids')

def register_device(device_id, device_name, screen_id, pairing_info):
    redis_session.sadd('device_ids', device_id)
    _rset('device_to_screen_id_%s' % device_id, screen_id)
    _rset('device_to_device_name_%s' % device_id, device_name)
    _rset('device_to_pairing_info_%s' % screen_id, pairing_info)
    _rset('screen_to_device_id_%s' % screen_id, device_id)
    _rset('screen_info_%s' % screen_id,
           {"init_time": time.time(), "broadcasts": {}})
    return screen_id

def get_device_name(device_id):
    return _rget('device_to_device_name_%s' % device_id)

def get_screen_id(device_id):
    return _rget('device_to_screen_id_%s' % device_id)

def screen_listen(screen_id):
    return blocking_listen('screen_channel_%s' % screen_id, timeout=10)

def get_screen(screen_id):
    return _rget('screen_info_%s' % screen_id)

## BROADCAST ##

def start_broadcast(broadcast_id, remote_id):
    redis_session.sadd('remote_ids', remote_id)
    _rset('remote_to_broadcast_id_%s' % (broadcast_id, ), remote_id)
    _rset('broadcast_to_remote_id_%s' % (remote_id, ), broadcast_id)
    _rset('broadcast_info_%s' % broadcast_id,
           {"init_time": time.time(), "screens": {}})
    _rset('remote_info_%s' % (remote_id, ), {'screens': {}})
    return broadcast_id

def get_broadcast(broadcast_id):
    return _rget('broadcast_info_%s' % broadcast_id)

def publish(broadcast_id, data):
    print "publishing..."
    broadcast_info = get_broadcast(broadcast_id)
    data = json.dumps(data)
    for screen_id in broadcast_info['screens']:
        print 'broadcasting to ', screen_id, '\n\tdata: ', data
        redis_session.publish(('screen_channel_%s' % screen_id), data)

## SUBSCRIPTION ##
def add_to_broadcast(screen_id, broadcast_id):
    broadcast_info = _rget('broadcast_info_%s' % broadcast_id)
    screen_info = _rget('screen_info_%s' % screen_id)

    start_time = time.time()

    # Update start times for the broadcast and screen info
    broadcast_info['screens'][screen_id] = start_time
    screen_info['broadcasts'][broadcast_id] = start_time

    # Create a record of the fact that this device has conencted
    # to this creen
    remote_id = _rget('remote_to_broadcast_id_%s' % (broadcast_id, ))
    remote_info = _rget('remote_info_%s' % (remote_id, ))
    remote_info['screens'][screen_id] = start_time

    _rset('screen_info_%s' % screen_id, screen_info)
    _rset('remote_info_%s' % (remote_id, ), remote_info)
    return _rset('broadcast_info_%s' % broadcast_id, broadcast_info)

def remove_from_broadcast(screen_id, broadcast_id):
    broadcast_info = _rget('broadcast_info_%s' % broadcast_id)
    screen_info = _rget('screen_info_%s' % screen_id)

    broadcast_info['screens'].pop(screen_id)
    screen_info['broadcasts'].pop(broadcast_id)

    _rset('screen_info_%s' % screen_id, screen_info)
    return _rset('broadcast_info_%s' % broadcast_id, broadcast_info)

def known_screens_for_broadcast(broadcast_id):
    remote_id = _rget('remote_to_broadcast_id_%s' % (broadcast_id, ))
    remote_info = _rget('remote_info_%s' % (remote_id, ))
    return [_rget('screen_info_%s' % (screen_id, )) for screen_id in remote_info['screens'].keys()]
