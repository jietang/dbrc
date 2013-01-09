from gevent import monkey
monkey.patch_all()

import multiprocessing

bind = "127.0.0.1:5000"
workers = 1 # multiprocessing.cpu_count() * 2 + 1
worker_class = 'gevent'
