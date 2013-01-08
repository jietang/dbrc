import requests

HOST='127.0.0.1'
PORT=5000

def request(rpc_name, *args):
    rpc_target = 'http://%s:%d/%s' % (HOST, PORT, rpc_name)
    if args:
        rpc_target += '/' + '/'.join(str(x) for x in args)
    print "making request: ", rpc_target
    res = requests.get(rpc_target).json()
    print "response: ", res
    return res
