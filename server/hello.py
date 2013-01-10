import json
import random
import time
import redis

from datetime import timedelta
from flask import render_template
from flask import Flask
from flask import Response
from flask import request, make_response, current_app
from flask.ext.sqlalchemy import SQLAlchemy
from functools import update_wrapper


redis_session = redis.StrictRedis(host='localhost', port=6379, db=0)
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+mysqldb://root:dbrcftw@localhost/dbrc?charset=utf8'
db = SQLAlchemy(app)

messages = db.Table(
    'messages', db.metadata,
    db.Column('msg_id', db.Integer, primary_key=True),
    db.Column('screen_id', db.Integer),
    db.Column('data', db.Text),
    db.Column('active', db.Integer),
    mysql_engine='InnoDB',
    mysql_charset='utf8',
)


# ability to pair permanently: persist broadcast_id on remote, broadcast to device mapping on server, when devices re-subscribe they are good to go
# ability to pair ephemerally: create broadcast with a timeout, each time a push is received we check to see if it is still active and delete it if not
# ability to pull from a broadcast? list of files on each screen, or just last one sent?
#  - map broadcast to last file sent
#

#
#
# redis pubsub for long poll notify, use an actual data store
# make screen.py more robust to kicking of server (re-register and re-subscribe)?
#
# data model:
# message queue
# map broadcast to multiple device ids
# map device_id to current active screen_id
#

# TODO
# pairing: implement mapping from screens->paired clients, paired clients->screens, timeouts
subscribing_device_ids = set()
broadcast_id_to_screen_ids = {}
# implement message queue w/sqlalchemy with put / pop_if_exists semantics
push_queue = []
# use redis for this? http://toastdriven.com/blog/2011/jul/31/gevent-long-polling-you/
device_id_to_screen_ids = {}
screen_id_to_device_id = {}


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

        options_resp = current_app.make_default_options_response()
        return options_resp.headers['allow']

    def decorator(f):
        def wrapped_function(*args, **kwargs):
            if automatic_options and request.method == 'OPTIONS':
                resp = current_app.make_default_options_response()
            else:
                resp = make_response(f(*args, **kwargs))
            if not attach_to_all and request.method != 'OPTIONS':
                return resp

            h = resp.headers

            h['Access-Control-Allow-Origin'] = origin
            h['Access-Control-Allow-Methods'] = get_methods()
            h['Access-Control-Max-Age'] = str(max_age)
            if headers is not None:
                h['Access-Control-Allow-Headers'] = headers
            return resp

        f.provide_automatic_options = False
        return update_wrapper(wrapped_function, f)
    return decorator

@app.route('/')
def home():
	return render_template('home.html')

# New routes
@app.route('/broadcasts/', methods=['GET', 'POST'])
@crossdomain(origin='*')
def broadcasts():
    if request.method == 'POST':
        new_broadcast = generate_random_id()
        broadcast_id_to_screen_ids[new_broadcast] = set()
        return Response(json.dumps({'broadcast_id': new_broadcast}), mimetype="text/json")
    else:
        broadcast_urls = ['/broadcasts/' + str(broadcast_id) for broadcast_id in broadcast_id_to_screen_ids.keys()]
        return Response(json.dumps(broadcast_urls), mimetype="text/json")


@app.route('/broadcasts/<int:broadcast_id>', methods=['GET', 'POST'])
@crossdomain(origin='*')
def broadcast(broadcast_id):
    if broadcast_id not in broadcast_id_to_screen_ids.keys():
        return Response(status=404)

    if request.method == 'POST':
        payload = request.json
        result = 'fail'
        for screen_id in broadcast_id_to_screen_ids[broadcast_id]:
            push_queue.append((screen_id, payload))
            result = 'ok'
        return Response(json.dumps(dict(result=result)), mimetype="text/json")
    else:
        return Response(json.dumps({'broadcast_id': broadcast_id}), mimetype="text/json")


@app.route('/broadcasts/<int:broadcast_id>/screens/', methods=['GET', 'POST'])
@crossdomain(origin='*')
def broadcasts_screens(broadcast_id):
    if request.method == 'POST':
        if broadcast_id not in broadcast_id_to_screen_ids.keys():
            return Response(status=404)
        screen_id = int(request.form.get('screen_id'))
        # Is the screen id valid?
        if screen_id not in screen_id_to_device_id.keys():
            return Response(json.dumps({'error': 'invalid screen_id'}), status=400, mimetype="text/json")

        broadcast_id_to_screen_ids[broadcast_id].add(screen_id)
        return Response(status=200)

    else:
        screen_urls = ['/screens/' + str(screen_id) for screen_id in broadcast_id_to_screen_ids[broadcast_id]]
        return Response(json.dumps(screen_urls), mimetype="text/json")

@app.route('/screens/', methods=['GET', 'POST'])
@crossdomain(origin='*')
def screens():
    if request.method == 'POST':
        device_id = request.form.get('device_id')
        screen_id = generate_random_id()
        device_id_to_screen_ids[device_id] = set([screen_id])
        screen_id_to_device_id[screen_id] = device_id
        return Response(json.dumps({'screen_id': screen_id}), mimetype="text/json")
    else:
        screen_urls = ['/screens/' + str(screen_id) for screen_id in screen_id_to_device_id.keys()]
        return Response(json.dumps(screen_urls), mimetype="text/json")


@app.route('/screens/<int:screen_id>', methods=['GET'])
@crossdomain(origin='*')
def screen(screen_id):
    # The long poll
    if screen_id in screen_id_to_device_id.keys():
        for _ in range(20):
            found = None
            for i, (msg_screen_id, _) in enumerate(push_queue):
                if screen_id == msg_screen_id:
                    found = i
                    break
            if found is not None:
                screen_id, payload = push_queue.pop(i)
                return json.dumps(dict(result='ok', data=payload))
            time.sleep(.25)

        # TODO generate a new screen id here if necessary, send it down
        return Response(json.dumps(dict(result='resubscribe', screen_id=screen_id)), mimetype="text/json")
    else:
        return Response(status=404)

def generate_random_id():
    return random.randint(0, 10000)

if __name__ == '__main__':
    app.run(port=5000, debug=True)
