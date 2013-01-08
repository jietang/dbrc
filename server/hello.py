import json
import time

from flask import render_template
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
screen_ids = set()
# implement message queue w/sqlalchemy with put / pop_if_exists semantics
push_queue = []

@app.route('/')
def db_test():
    user = { 'nickname': 'FakeUser' }
    return render_template("home.html",
        title = 'Home',
        user = user)
    with db.engine.connect() as conn:
        return str(conn.execute(db.select([messages], messages.c.msg_id == 1)).fetchall())

@app.route('/subscribe/<int:screen_id>')
def subscribe(screen_id):
    print "subscribe starting"
    screen_ids.add(screen_id)
    for _ in range(20):
        found = None
        for i, msg in enumerate(push_queue):
            if msg == screen_id:
                found = i
                break
        if found is not None:
            msg = push_queue.pop(i)
            return json.dumps(dict(result='ok', data='http://www.google.com'))
        print "sleeping ", screen_ids, push_queue
        time.sleep(.25)
    return json.dumps(dict(result='resubscribe'))

@app.route('/push/<int:screen_id>')
def push(screen_id):
    print "push ", screen_ids, screen_id
    if screen_id in screen_ids:
        push_queue.append(screen_id)
        return json.dumps(dict(result='ok'))
    else:
        return json.dumps(dict(result='fail'))

@app.route('/listpair')
def listpair():
    return json.dumps(dict(result='ok',
                           data=screen_ids))

if __name__ == '__main__':
    app.run(port=5000, debug=True)
