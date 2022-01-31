# Testing on compose

Although `docker-compose` isn't recommended for production deployments, this is still useful for local cluster testing.

```
wget https://raw.githubusercontent.com/resurfaceio/containers/master/compose/resurface.yml
docker-compose -f resurface.yml up --detach --scale worker=1
docker-compose -f resurface.yml down
```

🔥 specify `worker=2` or `worker=3` above for a larger cluster

⚠️ no container resource limits are set

⚠️ volatile storage only

☠️ not intended for use in production environments