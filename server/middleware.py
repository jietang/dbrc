import redis
import json
import controllers
import flask

from lib import colorize
from flask import (
    Flask,
    Request,
    Response,
    )

redis_session = redis.StrictRedis(host='localhost', port=6379, db=0)
app = Flask(__name__)

def dbrc_endpoint(fn):
    def inner(*args, **kwargs):
        print 'request for', colorize(flask.request.path, 'red'), \
               'args:', colorize(args, 'cyan'), \
               'kwargs:', colorize(kwargs, 'bright blue')
        print colorize(flask.request.args, 'green')
        for k, v in flask.request.args.iteritems():
            assert k not in kwargs, 'cannot take a duped param'
            kwargs[k] = v
        response = fn(*args, **kwargs)
        if isinstance(response, (list, int, set, basestring, dict, tuple)):
            response_contents = json.dumps(response)
            response = Response(response_contents, mimetype="text/json")
            print '\t', colorize(response_contents, 'yellow')
        else:
            reponse = Response("%s" % response, mimetype="text/html")
        return response
    inner.__name__ = fn.__name__
    return inner

def reg_endpoint(path, method):
    app.route(path)(dbrc_endpoint(method))

reg_endpoint('/', lambda: 'nothing here for now')

## screen endpoint
reg_endpoint("/register", controllers.register)
reg_endpoint("/listen", controllers.listen)

## broadcast endpoints
reg_endpoint("/create_broadcast", controllers.create_broadcast)
reg_endpoint("/publish", controllers.publish)

## general endpoints
reg_endpoint("/add_to_broadcast", controllers.add_to_broadcast)

## web endpoints

if __name__ == '__main__':
    app.run(port=80, debug=True, host='0.0.0.0')
    
