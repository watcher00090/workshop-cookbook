#!/bin/bash

## ((nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err) & echo Theia IDE started.....)'"
nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 &>/home/ubuntu/theia_startup_log.txt & echo "Theia ide started...."