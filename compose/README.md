# Testing on compose

Although `docker-compose` isn't recommended for production deployments, this is still useful for local cluster testing.

## Resizeable clusters without Iceberg

This configuration is intended for testing clusters with a variable number of nodes. All storage is mapped to `tmpfs` and will be lost when the cluster stops.

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/compose/resurface.yml
docker-compose -f resurface.yml up --detach --scale worker=1
docker-compose -f resurface.yml down --remove-orphans --volumes
```

🔥 specify `worker=2` or `worker=3` above for a larger cluster

⚠️ volatile storage only

☠️ not intended for use in production environments

## Fixed-size cluster with Iceberg

This configuration includes 3 Resurface nodes (1 coordinator and 2 workers), configured with Iceberg and Minio.  All storage is mapped to persistent volumes.

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/compose/resurface-iceberg.yml
docker-compose -f resurface-iceberg.yml up --detach
docker-compose -f resurface-iceberg.yml down --remove-orphans --volumes
```

⚠️ can't resize without modifying docker compose file

☠️ not intended for use in production environments
