#!/bin/bash

# Bashly script with docker
function bashly() {
    docker run -e BASHLY_ENV=production --rm -it --user $(id -u):$(id -g) --volume "${PWD}:/app" --pull always dannyben/bashly $1
}

bashly generate

mv -f ./l2-tools ../../
