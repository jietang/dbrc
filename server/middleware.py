import json
import flask
from environment import app
import controllers
from util import colorize

def dbrc_endpoint(fn):
    def inner(*args, **kwargs):
        print 'request for', colorize(flask.request.path, 'red'), \
               'args:', colorize(args, 'cyan'), \
               'kwargs:', colorize(kwargs, 'bright blue')
        print colorize(flask.request.values, 'green')
        for k, v in flask.request.values.iteritems():
            assert k not in kwargs, 'cannot take a duped param'
            kwargs[k] = v
        try:
            response = fn(*args, **kwargs)
            if isinstance(response, (list, int, set, basestring, dict, tuple)):
                response_contents = json.dumps(response)
                response = flask.Response(response_contents, mimetype="text/json")
                print '\t', colorize(response_contents, 'yellow')
            else:
                reponse = flask.Response("%s" % response, mimetype="text/html")
            return response
        except AssertionError, e:
            return flask.make_response('Server Assertion Error: ' + e.message, 400)
    inner.__name__ = fn.__name__
    return inner

def reg_endpoint(path, method, methods=tuple(["GET", "POST", "DELETE"])):
    app.route(path, methods=methods)(dbrc_endpoint(method))


reg_endpoint('/', lambda: 'nothing here for now')
reg_endpoint('/broadcasts/', controllers.post_broadcast)
reg_endpoint('/broadcasts/<int:broadcast_id>', controllers.post_to_broadcast)
reg_endpoint('/broadcasts/<int:broadcast_id>/screens', controllers.subscriptions)
reg_endpoint('/screens/', controllers.post_screen)
reg_endpoint('/screens/<int:screen_id>', controllers.long_poll)
reg_endpoint('/screens/<int:screen_id>/broadcasts', controllers.subscriptions)

if __name__ == '__main__':
    app.run(port=5000, debug=True, host='0.0.0.0')
