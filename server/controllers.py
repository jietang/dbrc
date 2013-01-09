import flask
import json

from lib import generate_random_id
import model


def post_broadcast():
    assert flask.request.method == 'POST', \
        'must use POST to start a broadcast, got %s' \
        % flask.request.method
    broadcast_id = generate_random_id()
    model.start_broadcast(broadcast_id)
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
    assert device_id, 'must provide a device id'
    screen_id = generate_random_id()

    info = flask.request.json.get('info')    
    return {"screen_id": model.register_device(device_id, screen_id)}


def long_poll(screen_id):
    assert flask.request.method == "GET", \
        "this method only supports a long-poll GET"
    return model.screen_listen(screen_id)
