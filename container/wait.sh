#!/bin/bash

set -e

function process_instance() {
  local instance=${1}
  local zone=${2}
  echo 'Waiting for the instance to finish...'
  while true; do
    # Try to read some information about the instance
    local result=$(
      gcloud compute instances describe --zone ${zone} ${instance} > /dev/null 2>&1
      echo $?
    )
    # Exit successfully when there is no such instance
    [ ${result} != 0 ] && break
    wait
  done
}

function process_success() {
  local instance=${1}
  echo 'Waiting for the success to be reported...'
  # Give it ten tries
  local count=10
  while true; do
    # Check if the last entry in Stackdriver contains “Well done”
    local result=$(
      gcloud logging read --limit 1 logName:${instance} |
      grep 'Well done' |
      wc -l
    )
    # Exit successfully if the phrase is present; otherwise, decrease the counter
    [ ${result} == 1 ] && break || ((count--))
    # Exit unsuccessfully when the counter hits zero
    [ ${count} == 0 ] && exit 1
    wait
  done
}

function wait() {
  echo 'Waiting...'
  sleep 10
}

# Invoke the function specified by the first command-line argument and forward
# the rest of the arguments to this function
process_${1} ${@:2:10}
