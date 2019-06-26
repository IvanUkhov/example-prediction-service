#!/bin/bash

set -e

function delete() {
  gcloud compute instances delete "${NAME}-${VERSION}-${ACTION}" \
    --delete-disks all \
    --zone ${ZONE} \
    --quiet
}

function info() {
  gcloud logging write "${NAME}-${VERSION}-${ACTION}" "${1}"
}

function load() {
  mkdir -p output
  # Sync the content of a folder in a bucket with the output directory
  gsutil -m rsync -r "${1}" output
}

function save() {
  # Sync the content of the output directory with a folder in a bucket
  gsutil -m rsync -r output "${1}"
}

function process_application() {
  export PYTHONPATH="source:${PYTHONPATH}"
  local stamp=$(date '+%Y-%m-%d')
  # Locate the latest trained model
  local input=$(gsutil ls gs://${NAME}/${VERSION}/training 2> /dev/null | sort | tail -1)
  local output="gs://${NAME}/${VERSION}/application/${stamp}"
  load "${input}"
  save "${output}"
  python -m prediction.main --action application --config configs/application.json
  save "${output}"
}

function process_training() {
  export PYTHONPATH="source:${PYTHONPATH}"
  local stamp=$(date '+%Y-%m-%d')
  local output="gs://${NAME}/${VERSION}/training/${stamp}"
  python -m prediction.main --action training --config configs/training.json
  save "${output}"
}

# Invoke the delete function where the scripts exits regardless of the reason
trap delete EXIT
# Report a successful start to Stackdriver
info "Running action '${ACTION}'..."
# Invoke the function specified by the ACTION environment variable
"process_${ACTION}"
# Report a successful completion to Stackdriver
info 'Well done.'
