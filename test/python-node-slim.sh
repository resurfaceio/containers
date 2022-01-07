#!/bin/bash
docker build -f python-node-slim.dockerfile -t python-node:$1-slim --no-cache .
docker tag python-node:$1-slim resurfaceio/python-node:$1-slim
docker push resurfaceio/python-node:$1-slim
