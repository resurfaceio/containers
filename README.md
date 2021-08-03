# Resurface containers
Containers and deployment scripts

## Run volatile cluster on docker compose

Start with two nodes, and add more nodes by increasing the count of workers.
All data is lost when the cluster is stopped or upgraded.

```
docker-compose -f resurface-volatile.yml up --detach --scale worker=1
```

## Run persistent cluster on docker compose

Start with two nodes, and add more nodes by editing the yml file to define more workers.
All data is stored in persistent docker volumes, which survive restarts and upgrades. 

```
docker-compose -f resurface-persistent.yml up --detach
```
