#!/bin/bash

set -e

function process_instance() {
  local instance=${1}
  local zone=${2}
  echo 'Waiting for the instance to finish...'
  while true; do
    local result=$(
      gcloud compute instances describe --zone ${zone} ${instance} > /dev/null 2>&1
      echo $?
    )
    [ ${result} != 0 ] && exit 0
    wait
  done
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
