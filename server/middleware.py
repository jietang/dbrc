import json
import flask
import traceback
from environment import app
import controllers
from util import colorize
from datetime import timedelta
from functools import update_wrapper

def dbrc_endpoint(fn):
    def inner(*args, **kwargs):
        print colorize(flask.request.method, 'yellow'), \
            'request for', colorize(flask.request.path, 'red'), \
            'args:', colorize(args, 'cyan'), \
            'kwargs:', colorize(kwargs, 'bright blue')
        print colorize(flask.request.values, 'green')
        try:
            for k, v in flask.request.values.iteritems():
                assert k not in kwargs, 'cannot take a duped param'
                kwargs[k] = v
            response = fn(*args, **kwargs)
            if isinstance(response, (list, int, set, basestring, dict, tuple)) or response is None:
                response_contents = json.dumps(response)
                response = flask.Response(response_contents, mimetype="text/json")
                # print '\t', colorize(response_contents, 'yellow')
            else:
                response = flask.Response("%s" % response, mimetype="text/html")

            # CORS header
            response.headers['Access-Control-Allow-Origin'] = '*'
            return response
        except AssertionError, e:
            return flask.make_response('Server Assertion Error: ' + e.message, 400)
        except Exception, e:
            traceback.print_exc()
            return flask.make_response("REAL ERROR: " + e.message, 500)
    inner.__name__ = fn.__name__
    return inner

def crossdomain(origin=None, methods=None, headers=None,
                max_age=21600, attach_to_all=True,
                automatic_options=True):
    if methods is not None:
        methods = ', '.join(sorted(x.upper() for x in methods))
    if headers is not None and not isinstance(headers, basestring):
        headers = ', '.join(x.upper() for x in headers)
    if not isinstance(origin, basestring):
        origin = ', '.join(origin)
    if isinstance(max_age, timedelta):
        max_age = max_age.total_seconds()

    def get_methods():
        if methods is not None:
            return methods

        options_resp = flask.current_app.make_default_options_response()
        return options_resp.headers['allow']

    def decorator(f):
        def wrapped_function(*args, **kwargs):
            if automatic_options and flask.request.method == 'OPTIONS':
                resp = flask.current_app.make_default_options_response()
            else:
                resp = flask.make_response(f(*args, **kwargs))
            if not attach_to_all and flask.request.method != 'OPTIONS':
                return resp

            h = resp.headers

            h['Access-Control-Allow-Origin'] = origin
            h['Access-Control-Allow-Methods'] = get_methods()
            h['Access-Control-Max-Age'] = str(max_age)
            h['Access-Control-Allow-Headers'] = 'Content-Type'
            return resp

        f.provide_automatic_options = False
        return update_wrapper(wrapped_function, f)
    return decorator


def reg_endpoint(path, method, methods=tuple(["OPTIONS", "GET", "POST", "DELETE"])):
    app.route(path, methods=methods)(crossdomain(origin='*')(dbrc_endpoint(method)))

# the original screen webpage: subscribes with auto-generated device ID
from flask import render_template
@app.route('/webscreen/')
def screen():
	return render_template('screen.html')

# for demo day: subscribes with device ID of "2"
@app.route('/')
def demo():
	return render_template('demo.html')

# this is necessary for frame-busting-busting
@app.route('/204/')
def view204():
	return '', 204

# the remote webpage
@app.route('/remote/')
def remote():
	return render_template('remote.html')

reg_endpoint('/broadcasts/', controllers.post_broadcast)
reg_endpoint('/broadcasts/<int:broadcast_id>/', controllers.post_to_broadcast)
reg_endpoint('/broadcasts/<int:broadcast_id>/screens/', controllers.subscriptions)
reg_endpoint('/broadcasts/<int:broadcast_id>/screens/<int:screen_id>', controllers.delete_screen_from_broadcast)
reg_endpoint('/broadcasts/<int:broadcast_id>/known_screens/', controllers.known_screens)
reg_endpoint('/broadcasts/<int:broadcast_id>/likely_screens/', controllers.likely_screens)
reg_endpoint('/screens/', controllers.post_screen)
reg_endpoint('/screens/<int:screen_id>', controllers.long_poll)
reg_endpoint('/screens/<int:screen_id>/broadcasts', controllers.subscriptions)
reg_endpoint('/screens/<int:screen_id>/broadcasts/<int:broadcast_id>', controllers.delete_screen_from_broadcast)

if __name__ == '__main__':
    app.run(port=80, debug=True, host='0.0.0.0')
