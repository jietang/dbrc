import json
import random
import time

from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

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

# TODO
# pairing: implement mapping from screens->paired clients, paired clients->screens, timeouts
subscribing_device_ids = set()
broadcast_id_to_device_ids = {}
# implement message queue w/sqlalchemy with put / pop_if_exists semantics
push_queue = []
# use redis for this? http://toastdriven.com/blog/2011/jul/31/gevent-long-polling-you/
device_id_to_screen_ids = {}
screen_id_to_device_id = {}


@app.route('/')
def db_test():
    print "db_test"
    with db.engine.connect() as conn:
        return str(conn.execute(db.select([messages], messages.c.msg_id == 1)).fetchall())

# push

@app.route('/subscribe/<int:screen_id>')
def subscribe(screen_id):
    device_id = screen_id_to_device_id[screen_id]
    subscribing_device_ids.add(device_id)
    for _ in range(20):
        found = None
        for i, msg in enumerate(push_queue):
            if msg == device_id:
                found = i
                break
        if found is not None:
            msg = push_queue.pop(i)
            return json.dumps(dict(result='ok', data='http://www.google.com'))
        time.sleep(.25)

    # TODO generate a new screen id here if necessary, send it down
    return json.dumps(dict(result='resubscribe', screen_id=screen_id))

def generate_random_id():
    return random.randint(0, 10000)

@app.route('/create_broadcast')
def create_broadcast():
    global broadcast_id_to_device_ids
    broadcast_id = generate_random_id()
    broadcast_id_to_device_ids[broadcast_id] = set()
    return json.dumps(dict(result='ok', broadcast_id=broadcast_id))

@app.route('/add_to_broadcast/<int:broadcast_id>/<int:screen_id>')
def add_to_broadcast(broadcast_id, screen_id):
    global broadcasts_to_screen_ids
    broadcast_id_to_device_ids[broadcast_id].add(screen_id_to_device_id[screen_id])
    return json.dumps(dict(result='ok'))

@app.route('/register/<int:device_id>')
def register(device_id):
    global device_to_screen_ids
    global screen_id_to_device
    screen_id = generate_random_id()
    device_id_to_screen_ids[device_id] = set([screen_id])
    screen_id_to_device_id[screen_id] = device_id
    return json.dumps(dict(result='ok', screen_id=screen_id))

@app.route('/push/<int:broadcast_id>')
def push(broadcast_id):
    result = 'fail'
    for device_id in broadcast_id_to_device_ids.get(broadcast_id, []):
        if device_id in subscribing_device_ids:
            push_queue.append(device_id)
            result = 'ok'
    return json.dumps(dict(result=result))

@app.route('/listpair')
def listpair():
    return json.dumps(dict(result='ok',
                           data=subscribing_device_ids))

if __name__ == '__main__':
    app.run(port=5000, debug=True)
