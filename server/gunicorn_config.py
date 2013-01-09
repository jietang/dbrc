from gevent import monkey
monkey.patch_all()

import multiprocessing

bind = "0.0.0.0:5000"
workers = 1 # multiprocessing.cpu_count() * 2 + 1
worker_class = 'gevent'
