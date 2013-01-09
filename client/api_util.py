import requests
import os

is_prod = os.getenv('IS_PROD', False)
HOST = 'ec2-54-235-229-59.compute-1.amazonaws.com' if is_prod else '127.0.0.1'
PORT = 5000 if is_prod else 5000

def request(rpc_name, *args):
    rpc_target = 'http://%s:%d/%s' % (HOST, PORT, rpc_name)
    if args:
        rpc_target += '/' + '/'.join(str(x) for x in args)
    print "making request: ", rpc_target
    resp = requests.get(rpc_target)
    print "code: ", resp.status_code
    if resp.status_code == 200:
        print "response: ", resp.json()
        return resp.json()
    elif resp.status_code == 500:
        raise Exception(resp)
