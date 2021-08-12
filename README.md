# Resurface containers
Containers and deployment scripts

## Run persistent cluster on docker compose

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/resurface/resurface-persistent.yml
docker-compose -f resurface-persistent.yml up --detach
docker-compose -f resurface-persistent.yml down
```

## Run volatile cluster on docker compose

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/resurface/resurface-volatile-2node.yml
docker-compose -f resurface-volatile.yml up --detach
docker-compose -f resurface-volatile.yml down
```
