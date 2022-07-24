#!/bin/bash
docker build -f alpine-jdk17.dockerfile -t alpine-jdk17:$1 --no-cache .