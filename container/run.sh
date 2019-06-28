#!/bin/bash

set -e

function process_training() {
  # Make Python be able to find the prediction package in the source directory
  export PYTHONPATH="source:${PYTHONPATH}"
  # Generate a timestamp for the current run
  local stamp=$(date '+%Y-%m-%d')
  # Define the output location in Cloud Storage
  local output="gs://${NAME}/${VERSION}/training/${stamp}"
  # Invoke training
  python -m prediction.main \
    --action training \
    --config configs/training.json
  # Copy the result to the output location in Cloud Storage
  save "${output}"
}

function process_application() {
  # Make Python be able to find the prediction package in the source directory
  export PYTHONPATH="source:${PYTHONPATH}"
  # Generate a timestamp for the current run
  local stamp=$(date '+%Y-%m-%d')
  # Find the latest trained model in Cloud Storage
  local input=$(
    gsutil ls "gs://${NAME}/${VERSION}/training" 2> /dev/null |
    sort |
    tail -1
  )
  # Define the output location in Cloud Storage
  local output="gs://${NAME}/${VERSION}/application/${stamp}"
  # Copy the model from the input location in Cloud Storage
  load "${input}"
  # Copy the model to the output location in Cloud Storage
  save "${output}"
  # Invoke application
  python -m prediction.main \
    --action application \
    --config configs/application.json
  # Copy the result to the output location in Cloud Storage
  save "${output}"
}

function delete() {
  # Delete a Compute Engine instance called "${NAME}-${VERSION}-${ACTION}"
  gcloud compute instances delete "${NAME}-${VERSION}-${ACTION}" \
    --delete-disks all \
    --zone ${ZONE} \
    --quiet
}

function info() {
  # Write into a Stackdriver log called "${NAME}-${VERSION}-${ACTION}"
  gcloud logging write "${NAME}-${VERSION}-${ACTION}" "${1}"
}

function load() {
  # Sync the content of a location in a bucket with the output directory
  mkdir -p output
  gsutil -m rsync -r "${1}" output
}

function save() {
  # Sync the content of the output directory with a location in a bucket
  gsutil -m rsync -r output "${1}"
}

# Invoke the delete function when the script exits regardless of the reason
trap delete EXIT
# Report a successful start to Stackdriver
info "Running action '${ACTION}'..."
# Invoke the function specified by the ACTION environment variable
"process_${ACTION}"
# Report a successful completion to Stackdriver
info 'Well done.'
