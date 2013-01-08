from middleware import redis_session as _r

def register(device_id):
    random_screen_id = 
    _r.set('device_to_screen_id_%s' % device_id, screen_id)

def listen(screen_id):


def generate_random_id():


def create_broadcast():


def add_to_broadcast(broadcast_id, screen_id):


def publish(broadcast_id, payload):


