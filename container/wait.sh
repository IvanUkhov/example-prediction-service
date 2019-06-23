#!/bin/bash

set -e

function process_container() {
  while true; do
    wait
  done
}

function process_instance() {
  local instance=${1}
  local zone=${2}
  echo 'Waiting for the instance to start...'
  local count=10
  while true; do
    local result=$(
      gcloud compute scp --zone ${zone} \
        "${BASH_SOURCE[0]}" ${instance}:/tmp/wait.sh &> /dev/null
      echo $?
    )
    [ ${result} == 0 ] && break || ((count--))
    [ ${count} == 0 ] && exit 1
    wait
  done
  echo 'Waiting for the instance to finish...'
  gcloud compute ssh --zone ${zone} ${instance} -- source /tmp/wait.sh container
}

function process_success() {
  local instance=${1}
  echo 'Waiting for the success to be reported...'
  local count=10
  while true; do
    local result=$(
      gcloud logging read --limit 1 "logName:${instance}" |
      grep 'Well done' |
      wc -l
    )
    [ ${result} == 1 ] && break || ((count--))
    [ ${count} == 0 ] && exit 1
    wait
  done
}

function wait() {
  echo 'Waiting...'
  sleep 10
}

"process_${1}" ${@:2:10}
