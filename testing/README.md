# Tester

This is a basic web application for sending API commands to the Geth customer nodes
running in the test network. It is intended to be used with the Docker stack
defined in the configuration/docker directory.

## Usage

Test files are written in YAML and an example is included in
testing/tests/example.yml. `calls` contains a list of API calls. Each item must
contain a node parameter, which defines which node to run the call against.
Nodes are not ordered and the order may change in different test runs. Using
`node: -1` will execute the call on every node. Calls are executed in file order.

To run a test, do a GET request for `/test/<test name>`. For example, to call
the `example.yml` test using the included configuration, run:

    curl http://127.0.0.1:8080/test/example.yml

from the machine the port is published on (in this case 402raspberrypi_1).
