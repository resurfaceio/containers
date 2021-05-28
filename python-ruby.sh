#!/bin/bash
docker build -f python-ruby.dockerfile -t python-ruby:$1 --no-cache .
docker tag python-ruby:$1 resurfaceio/python-ruby:$1
docker push resurfaceio/python-ruby:$1