#!/bin/bash
cd /home/ubuntu/ide
while ! yarn install; do # install the dependencies for the IDE
    sleep 10
done
while ! yarn theia build; do # build the IDE
    sleep 10
done

# start the IDE
yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000