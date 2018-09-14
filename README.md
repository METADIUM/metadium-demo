## metadium-demo

Demo for go-metadium, including docker containers and a simple hash table smart contract.

### Building & Setting Up

Docker and docker-compose are required to be installed. With that, the following command sets up a metadium network with three nodes: meta1, meta2 and meta3.

    git clone https://github.com/metadium/metadium-demo
    cd metadium-demo/containers/docker
    docker-compose up

### Tearing Down

    docker-compose down

### Ports

Ports 10009 &amp; 10010 are mapped as follows.

    meta1: 30109 & 30110
    meta2: 30209 & 30210
    meta3: 30309 & 30310

e.g.

    // Request
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' http://localhost:30110

    // Result
    {"jsonrpc":"2.0","id":1,"result":["0x4ce5c113c994e4f87f0729baec89e59813faaf53","0x044a6249451cfab7adf0e486ee0b6235aadf44ef","0x9a4073a0121c0967c5325f5a789c73b1a0caaf0b","0x1b7398d5f3754ee2ec1f1ecb1f60c4fb6c3d4e0a"]}

### Shell Access To Metadium Instances

    docker exec -it meta1 /bin/bash

Now one needs to use internal ports, i.e. 10010, not redirected ports.

    // Request
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' http://localhost:10010

    // Result
    {"jsonrpc":"2.0","id":1,"result":["0x4ce5c113c994e4f87f0729baec89e59813faaf53","0x044a6249451cfab7adf0e486ee0b6235aadf44ef","0x9a4073a0121c0967c5325f5a789c73b1a0caaf0b","0x1b7398d5f3754ee2ec1f1ecb1f60c4fb6c3d4e0a"]}
