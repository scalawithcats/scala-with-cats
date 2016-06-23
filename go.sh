#!/usr/bin/env bash
## Setup the environment variables Docker Machine needs. This assumes
##
## 1. you're running on an environment that uses Docker Machine (i.e. not Linux); and
## 2. your running machine is called default
eval "$(docker-machine env --shell bash default)"
docker-compose run book bash
