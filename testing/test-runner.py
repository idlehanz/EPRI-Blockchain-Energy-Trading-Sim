#!/usr/bin/env python3

import dns.resolver
import requests
import yaml
import json
import sys

from flask import Flask

TASK_NAME="tasks.eth_customer"
TEST_DIR="/root/tests/"
PORT=8545

def get_nodes():
    nodelist = []

    response = dns.resolver.query(TASK_NAME, 'A')
    for r in response:
        ip = str(r)
        if ip.startswith("10."):
            nodelist.append(Node(str(r)))

    return nodelist

class Node:
    def __init__(self, ip):
        self.url = "http://{}:{}".format(ip, PORT)
        print(self.url)
        self.call_id = 1

    def send_rpc_call(self, args):
        # Create payload
        data = {
            "jsonrpc": "2.0",
            "params": [],
        }
        data.update(args)

        # Set ID
        data["id"] = self.call_id
        self.call_id += 1

        try:
            # Send request
            r = requests.post(self.url, json=data)
            response = r.json()
        except:
            response = {"error": True}

        return {"request": data, "response": response, "url": self.url}

def run_test(path):
    test = {}
    with open(path, 'r') as testfile:
        test = yaml.load(testfile)

    nodes = get_nodes()
    test_output = []

    if len(nodes) < test["config"]["min_nodes"]:
        print("Not enough nodes (need {}, have {}). Try docker service scale"
              .format(test["config"]["min_nodes"],
                      len(nodes)))
        return

    print("Starting test")
    for call in test["calls"]:
        node_id = call.pop("node", None)
        result = nodes[node_id].send_rpc_call(call)
        test_output.append(result)
    print("Test completed")

    return json.dumps(test_output, indent=4)

app = Flask(__name__)

@app.route('/test/<testname>')
def test(testname):
    test_path = TEST_DIR + testname
    return run_test(test_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0')
