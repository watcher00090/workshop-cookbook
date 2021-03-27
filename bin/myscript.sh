#!/bin/bash
myres=$(curl http://3.141.19.113:2999/ >> log.txt)
if [ ! "$myres" ];
then
    echo 'connection failed...'; 
fi