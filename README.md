# Resurface containers
Containers and deployment scripts

## Run volatile cluster with 2 nodes

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/resurface-compose-volatile.yml
docker-compose -f resurface-compose-volatile.yml up --detach --scale worker=1
docker-compose -f resurface-compose-volatile.yml down
```

🔥 specify `worker=2` or `worker=3` above for a larger cluster

## Run persistent cluster with 2 nodes

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/resurface-compose-persistent.yml
docker-compose -f resurface-compose-persistent.yml up --detach
docker-compose -f resurface-compose-persistent.yml down
```

😢 adding more nodes requires editing this yaml template