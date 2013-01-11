from lib import blocking_listen, non_blocking_listen, _rset, _rget
from environment import redis_session
import json
import time


## SCREEN ##
def get_all_device_ids():
    return redis_session.smembers('device_ids')


def get_all_remote_ids():
    return redis_session.smembers('remote_ids')


def get_device_pairing_info(device_id):
    return _rget('device_to_pairing_info_%s' % device_id)


def register_device(device_id, device_name, screen_id, pairing_info):
    redis_session.sadd('device_ids', device_id)
    _rset('device_to_screen_id_%s' % device_id, screen_id)
    _rset('device_to_device_name_%s' % device_id, device_name)
    _rset('device_to_pairing_info_%s' % device_id, pairing_info)
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

def screen_get_queue(screen_id):
    return non_blocking_listen('screen_channel_%s' % screen_id, timeout=10)

def get_screen(screen_id):
    return _rget('screen_info_%s' % screen_id)

def _send_to_screen(screen_id, data):
    print 'broadcasting to', screen_id, '\n\tdata: ', data
    screen_channel = 'screen_channel_%s' % screen_id
    redis_session.publish((screen_channel), data)
    screen_queue = _rget('screen_message_queue_%s' % screen_channel) or []
    screen_queue.append(data)
    _rset('queue_%s' % screen_channel, screen_queue[:100])

## BROADCAST ##

def start_broadcast(broadcast_id, remote_id):
    redis_session.sadd('remote_ids', remote_id)
    _rset('remote_to_broadcast_id_%s' % (broadcast_id, ), remote_id)
    _rset('broadcast_to_remote_id_%s' % (remote_id, ), broadcast_id)
    _rset('broadcast_info_%s' % broadcast_id,
           {"init_time": time.time(), "screens": {}})
    return broadcast_id

def get_broadcast(broadcast_id):
    return _rget('broadcast_info_%s' % broadcast_id)

def set_broadcast_pairing_info(broadcast_id, connected):
    _rset('broadcast_pairing_info_%s' % broadcast_id, dict(connected=connected))

def get_broadcast_pairing_info(broadcast_id):
    return _rget('broadcast_pairing_info_%s' % broadcast_id)

def publish(broadcast_id, data):
    print "publishing..."
    broadcast_info = get_broadcast(broadcast_id)
    data = json.dumps(data)
    screen_ids = []
    for screen_id in broadcast_info['screens']:
        _send_to_screen(screen_id, data)
        screen_ids.append(screen_id)
    return screen_ids

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
    device_id = _rget('screen_to_device_id_%s' % (screen_id, ))
    remote_info = _rget('remote_info_%s' % (remote_id, ))
    if not remote_info:
        remote_info = {'devices': {}}
    remote_info['devices'][device_id] = start_time

    _rset('screen_info_%s' % screen_id, screen_info)
    _rset('remote_info_%s' % (remote_id, ), remote_info)
    return _rset('broadcast_info_%s' % broadcast_id, broadcast_info)

def remove_from_broadcast(screen_id, broadcast_id):
    broadcast_info = _rget('broadcast_info_%s' % broadcast_id)
    screen_info = _rget('screen_info_%s' % screen_id)

    try:
        broadcast_info['screens'].pop(screen_id)
    except KeyError:
        pass
    else:
        _rset('broadcast_info_%s' % broadcast_id, broadcast_info)

    try:
        screen_info['broadcasts'].pop(broadcast_id)
    except KeyError:
        pass
    else:
        _rset('screen_info_%s' % screen_id, screen_info)

    return {'broadcast_id': broadcast_id, 'screen_id': screen_id}

def known_screens_for_broadcast(broadcast_id):
    remote_id = _rget('remote_to_broadcast_id_%s' % (broadcast_id, ))
    remote_info = _rget('remote_info_%s' % (remote_id, ))
    devices_data = []
    if remote_info:
        for device_id in remote_info.get('devices', {}).keys():
            # TODO expiration for known devices?
            # For each device, get its current screen and the device name
            devices_data.append({
                'screen_id': str(_rget('device_to_screen_id_%s' % (device_id, ))),
                'device_name': _rget('device_to_device_name_%s' % (device_id, )),
                'known': True,
                })

    return devices_data
