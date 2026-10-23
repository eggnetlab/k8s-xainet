#!/bin/bash

# Bashly script with docker
function bashly() {
    docker run -e BASHLY_ENV=production --rm -it --user $(id -u):$(id -g) --volume "${PWD}:/app" dannyben/bashly:2.0.0 $1
}

bashly generate

mv -f ./xai-tools ../../
