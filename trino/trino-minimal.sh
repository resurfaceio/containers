#!/bin/bash
docker build -f trino-minimal.dockerfile -t trino-minimal:$1 --no-cache .