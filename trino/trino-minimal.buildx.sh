#!/bin/bash
docker buildx build --platform linux/amd64,linux/arm64 -f trino-minimal.dockerfile -t resurfaceio/trino-minimal:$1 --no-cache --push .