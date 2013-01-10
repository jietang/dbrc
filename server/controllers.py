import flask
import json

from lib import generate_random_id
import model


def post_broadcast(remote_id=None):
    assert flask.request.method == 'POST', \
        'must use POST to start a broadcast, got %s' \
        % flask.request.method

    assert remote_id != None, 'must post with remote_id'
    broadcast_id = generate_random_id()
    model.start_broadcast(broadcast_id, remote_id)
    return {"broadcast_id": broadcast_id}


def post_to_broadcast(broadcast_id, data=None):
    assert flask.request.method == 'POST', \
        'must use POST to publish things'
    assert data, \
        'must supply a data parameter to publish things'
    try:
        data = json.loads(data)
    except ValueError, e:
        # asserts cause a 400 to fire. this is a hack, but it's hack week.
        assert False, "'data' must be a valid JSON string"
    return {"publish_response": model.publish(broadcast_id, data)}


def subscriptions(broadcast_id=None, screen_id=None):
    method = flask.request.method
    assert method in ('GET', 'DELETE', 'POST')
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
    elif method == "DELETE":
        assert screen_id, 'need to specify a screen_id'
        return model.remove_from_broadcast(screen_id, broadcast_id)


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
    return dict(screen_id=model.get_screen_id(device_id), device_name=model.get_device_name(device_id))

def likely_hosts(broadcast_id):
    devices = model.get_all_device_ids()
    return [_prepare_device_info(device_id) for device_id in devices]

    # get all devices
    # for all devices, look up their pairing info
    #  match their pairing info against the info for the given broadcast
    #  ordering algorithm

def long_poll(screen_id):
    assert flask.request.method == "GET", \
        "this method only supports a long-poll GET"
    return model.screen_listen(screen_id)


def known_hosts(broadcast_id):
    assert flask.request.method == "GET", \
        "this method only supports a GET"
    # Get the device running the broadcast, then get its previous screens
    return models.known_screens_for_broadcast(broadcast_id)
