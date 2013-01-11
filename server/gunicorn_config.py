from gevent import monkey
monkey.patch_all()

import multiprocessing

bind = "0.0.0.0:80"
workers = 2 # multiprocessing.cpu_count() * 2 + 1
worker_class = 'gevent'
