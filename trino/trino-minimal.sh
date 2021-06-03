#!/bin/bash
docker build -f trino-minimal.dockerfile -t trino-minimal:$1 --no-cache .
docker tag trino-minimal:$1 resurfaceio/trino-minimal:$1
docker push resurfaceio/trino-minimal:$1