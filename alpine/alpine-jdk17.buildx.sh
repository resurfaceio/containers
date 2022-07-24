#!/bin/bash
docker buildx build --platform linux/amd64,linux/arm64 -f alpine-jdk17.dockerfile -t resurfaceio/alpine-jdk17:$1 --no-cache --push .