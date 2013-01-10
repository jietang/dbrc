import flask

from lib import generate_random_id
import model


def post_broadcast():
    assert flask.request.method == 'POST', \
        'must use POST to start a broadcast, got %s' \
        % flask.request.method

    remote_id = flask.request.json and flask.request.json.get('remote_id')
    assert remote_id != None, 'must post with remote_id'
    broadcast_id = generate_random_id()
    model.start_broadcast(broadcast_id, remote_id)

    if flask.request.json:
        connected = flask.request.json.get('connected')
        if connected:
            model.set_broadcast_pairing_info(broadcast_id, connected)

    return {"broadcast_id": broadcast_id}


def post_to_broadcast(broadcast_id):
    assert flask.request.method == 'POST', \
        'must use POST to publish things'
    try:
        data = flask.request.json
    except ValueError:
        # asserts cause a 400 to fire. this is a hack, but it's hack week.
        assert False, "'data' must be a valid JSON string"
    return {"screen_ids": model.publish(broadcast_id, data)}

def delete_screen_from_broadcast(broadcast_id, screen_id):
    assert flask.request.method == 'DELETE'
    return model.remove_from_broadcast(screen_id, broadcast_id)    

def subscriptions(broadcast_id=None, screen_id=None):
    method = flask.request.method
    assert method in ('GET', 'POST')
    if method == "GET":
        assert broadcast_id or screen_id, \
            'provide a broadcast or a screen'
        if broadcast_id and screen_id:
            screens = model.get_broadcast(broadcast_id)['screens']
            return screen_id in screens
        elif broadcast_id:
            return model.get_broadcast(broadcast_id)['screens']
        elif screen_id:
            return model.get_screen(screen_id)['broadcasts']
    elif method == "POST":
        assert screen_id, 'need to specify a screen_id'
        print 'adding screen %s to broadcast %s' % (screen_id, broadcast_id)
        model.add_to_broadcast(screen_id, broadcast_id)
        return {'broadcast_id': broadcast_id, 'screen_id': screen_id}


def post_screen():
    assert flask.request.method == 'POST', \
        'must POST a new screen'
    device_id = flask.request.json.get('device_id')
    device_name = flask.request.json.get('device_name')
    assert device_id, 'must provide a device id'
    assert device_name, 'must provide a device name'
    screen_id = generate_random_id()

    pairing_info = flask.request.json.get('pairing_info')
    return {"screen_id": model.register_device(device_id, device_name, screen_id, pairing_info)}

def _prepare_device_info(device_id):
    return dict(screen_id=model.get_screen_id(device_id), device_name=model.get_device_name(device_id),known=False)

def likely_screens(broadcast_id):
    pairing_info = model.get_broadcast_pairing_info(broadcast_id)
    device_ids = model.get_all_device_ids()
    if not pairing_info or not device_ids:
        return []

    likely_devices = []
    for device_id in device_ids:
        device_pairing_info = model.get_device_pairing_info(device_id)
        if not device_pairing_info:
            continue

        if pairing_info.get('connected', {}).get('ssid', None) in [d['ssid'] for d in device_pairing_info.get('nearby', {})]:
            likely_devices.append(device_id)
    return [_prepare_device_info(device_id) for device_id in likely_devices]

def long_poll(screen_id):
    assert flask.request.method == "GET", \
        "this method only supports a long-poll GET"
    return model.screen_listen(screen_id)

def fast_poll(screen_id):
    assert flask.request.method == "GET", \
        "this method only supports GET"
    return model.screen_get_queue(screen_id)

def known_screens(broadcast_id):
    assert flask.request.method == "GET", \
        "this method only supports a GET"
    # Get the device running the broadcast, then get its previous screens
    known_devices = model.known_screens_for_broadcast(broadcast_id)
    known_device_ids = set(x['screen_id'] for x in known_devices)
    likely_devices = likely_screens(broadcast_id)
    return known_devices + [x for x in likely_devices if x['screen_id'] not in known_device_ids]
