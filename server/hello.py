import json
from flask import Flask

app = Flask(__name__)

screen_ids = []

@app.route('/')
def hello_world():
    return 'Hello rob2 !'

@app.route('/subscribe/<int:screen_id>')
def subscribe(screen_id):
    screen_ids.append(screen_id)
    return json.dumps(dict(result='ok'))

@app.route('/listpair')
def listpair():
    return json.dumps(dict(result='ok',
                           data=screen_ids))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
