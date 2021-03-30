# Testbed

## Creating and destroying

The testbed can be created using the provided `create-testbed.sh` script:

    ./create-testbed.sh

This script creates two instances in the Amazon us-east-2b with an existing VPC, and configures them with the subnets, interfaces, IP addresses, security groups, and software needed.

The script uses the AWS CLI. If you do not have the AWS CLI installed, you can do so by following these instructions:

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html

When finished, all of the testbed resources can be destroyed by running:

    ./destroy-testbed.sh

## Gatekeeper instance

The Gatekeeper instance is already configured to be running BIRD. To stop it and run it yourself:

```
sudo pkill bird
sudo pkill gatekeeper
```

From the `gatekeeper` directory, run Gatekeeper:

    sudo ./build/gatekeeper


From the home directory, run BIRD:

    sudo bird -c gk-bird.conf

## Client instance

The client instance is already configured to be running BIRD. To stop it and run it yourself:

```
sudo pkill bird
sudo bird -c client-bird.conf
```

# Testbed information

The testbed has two instances -- a client and a Gatekeeper server:


```
+-----------+                   +-----------+
|           |                   |           |
|          [1]-----------------[2]         [3]
|           |                   |           |
|  Client   |                   | Gatekeeper|
+-----------+                   +-----------+
```

Both instances have a "management" interface that is connected to the Internet (not shown). They also have the following ports to interact with each other:

* Client port (1):
    * 172.31.1.184
    * 2600:1f16:354:f701:795:5efd:5335:9876

* Gatekeeper front interface (2):
    * 172.31.1.43
    * 2600:1f16:354:f701:795:5efd:5335:1439

* Gatekeeper back interface (3):
    * 172.31.2.102
    * 2600:1f16:354:f702:795:5efd:5335:1501

# Testing

## Test BGP

The testbed starts with a BIRD speaker on each instance connected to each other. They are both configured to exchange a route announcement. You can check the connectivity and routes exchanged by SSHing into one of them (say, the client) and running:

    sudo birdc

When in the `birdc` prompt, run the following:

    show protocols all

If you scroll down, you should see the BGP connection information:

```
bgp1       BGP        ---        up     19:45:49.568  Established
  BGP state:          Established
    Neighbor address: 172.31.1.43
    Neighbor AS:      4000
    Local AS:         3000
    Neighbor ID:      172.31.1.43
...
```

## Test pinging the Gatekeeper server from the client

From the client, to ping the Gatekeeper server's front interface (IPv4 and IPv6):

    ping 172.31.1.43
    ping -6 2600:1f16:354:f701:795:5efd:5335:1439

To ping the Gatekeeper server's back interface (IPv4 and IPv6):

    ping 172.31.2.102
    ping -6 2600:1f16:354:f702:795:5efd:5335:1501

## Testing pinging the client from the Gatekeeper server

From the Gatekeeper server, to ping the client use the `-I` flag to force the ping through the KNI, which passes packets through Gatekeeper and out the front interface:

    ping -I kni_front 172.31.1.184
    ping -I kni_front -6 2600:1f16:354:f701:795:5efd:5335:9876
