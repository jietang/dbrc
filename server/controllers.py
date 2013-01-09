import flask

from lib import (
    generate_random_id,
    )
import model


def post_broadcast():
    assert flask.request.method == 'POST', \
        'must use POST to start a broadcast'
    broadcast_id = generate_random_id()
    model.start_broadcast(broadcast_id)
    return broadcast_id


def post_to_broadcast(broadcast_id, data=None):
    assert flask.request.method == 'POST', \
        'must use POST to publish things'
    assert data, \
        'must supply a data parameter to publish things'
    model.publish(broadcast_id, data)
    return 'ok'


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
            return model.get_screen(broadcast_id)['broadcases']
    elif method == "POST":
        assert screen_id, 'need to specify a screen_id'
        return model.add_to_broadcast(screen_id, broadcast_id)
    elif method == "DELETE":
        assert screen_id, 'need to specify a screen_id'
        return model.remove_from_broadcast(screen_id, broadcast_id)


def post_screen(device_id=None):
    assert flask.request.method == 'POST', \
        'must POST a new screen'
    assert device_id, 'must provide a device id'
    screen_id = generate_random_id()
    return model.register_device(device_id, screen_id)


def long_poll(screen_id):
    assert flask.request.method == "GET", \
        "this method only supports a long-poll GET"
    return model.screen_listen(screen_id)
