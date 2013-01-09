import redis
from flask import Flask

redis_session = redis.StrictRedis(host='localhost', port=6379, db=0)
app = Flask(__name__)
