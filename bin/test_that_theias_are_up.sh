#!/bin/bash
# 
# This script assumes the existence of a file 'master_ips.txt' in the same directory as it, and also assumes that 'master_ips.txt' has one public IP address per line, and no commas (it can have blank lines, though)
# 
# This script returns with status 0 if able to connect to all the Theias on port 3000, and with status 1 otherwise
# 
# Note: this script won't run on some versions of RHEL / CentOS, unfortunately (see https://stackoverflow.com/questions/4922943/test-if-remote-tcp-port-is-open-from-a-shell-script/14701003#14701003)

using_immediate_stop_mode=0
if echo $* | grep -e "--stop-immediately-when-inaccessible-node-found" -q 
then
  echo ">>>> running with immediate_stop_mode enabled...."
  using_immediate_stop_mode=1
else
  echo ">>>> running with immediate_stop_mode disabled...."
fi 

# get the directory containing this script, irregardless of where the script is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

theia_ide_port=3000
TIMEOUT_SECONDS=5
num_attempted_connections=0
num_successful_connections=0

input="$DIR/master_ips.txt"

if [[ ! -f $input ]];
then
  echo "ERROR: this script requires that there be a file 'master_ips.txt' in the same directory. It will test if it can reach port 3000 for every ip address in this file. Please ensure the presence of this file in this directory and try again."
  exit 1
fi

while IFS= read -r line
do
  num_attempted_connections=$(($num_attempted_connections+1))
  ip_address=$line
  if [ ! -z "$ip_address" ]; 
  then
    nc -z -w $TIMEOUT_SECONDS -v $ip_address $theia_ide_port </dev/null &>/dev/null
    RETURN_STATUS=$?
    if [[ $RETURN_STATUS == 0 ]]; 
    then 
      echo "Successfully connected to ${ip_address} on port $theia_ide_port!"; 
      num_successful_connections=$(($num_successful_connections+1))
    else
      echo "Failed to connect to ${ip_address} on port $theia_ide_port"
      if [[ $using_immediate_stop_mode == 1 ]];
      then 
        exit 1
      fi
    fi    
  fi

done < "$input"

num_inaccessible_hosts=$(($num_attempted_connections - $num_successful_connections))

if [[ $num_inaccessible_hosts -gt 0 ]];
then
  echo "Summary: out of $num_attempted_connections attempted connections, we found $num_inaccessible_hosts inaccessible host(s)."
  exit 1
else 
  echo "Summary: successfully connected to all instances on port 3000, hooray!"
  exit 0
fi
