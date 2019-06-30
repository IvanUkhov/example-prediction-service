#!/bin/bash

set -e

function process_training() {
  # Make Python be able to find the prediction package in the source directory
  export PYTHONPATH="source:${PYTHONPATH}"
  # Generate a timestamp for the current run
  local timestamp=$(date '+%Y-%m-%d')
  # Invoke training
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Set the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Copy the trained model from the output directory to Cloud Storage
  save output ${output}
}

function process_application() {
  # Make Python be able to find the prediction package in the source directory
  export PYTHONPATH="source:${PYTHONPATH}"
  # Generate a timestamp for the current run
  local timestamp=$(date '+%Y-%m-%d')
  # Find the latest trained model in Cloud Storage
  local input=$(
    gsutil ls gs://${NAME}/${VERSION}/training 2> /dev/null |
    sort |
    tail -1
  )
  # Copy the trained model from Cloud Storage to the output directory
  load ${input} output
  # Invoke application
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Set the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Copy the predictions from the output directory to Cloud Storage
  save output ${output}
  # Set the input file in Cloud Storage
  local input=${output}/predictions.csv
  # Set the output data set and table in BigQuery
  local output=$(echo ${NAME} | tr - _).predictions
  # Ingest the predictions from Cloud Storage into BigQuery
  ingest ${input} ${output} player_id:STRING,label:BOOL
}

function delete() {
  # Delete a Compute Engine instance called "${NAME}-${VERSION}-${ACTION}"
  gcloud compute instances delete ${NAME}-${VERSION}-${ACTION} \
    --delete-disks all \
    --zone ${ZONE} \
    --quiet
}

function ingest() {
  # Ingest a file from Cloud Storage into a table in BigQuery
  local input="${1}"
  local output="${2}"
  local schema="${3}"
  bq load \
    --source_format CSV \
    --skip_leading_rows 1 \
    --replace \
    ${output} \
    ${input} \
    ${schema}
}

function load() {
  # Sync the content of a location in Cloud Storage with a local directory
  local input="${1}"
  local output="${2}"
  mkdir -p "${output}"
  gsutil -m rsync -r "${input}" "${output}"
}

function save() {
  # Sync the content of a local directory with a location in Cloud Storage
  local input="${1}"
  local output="${2}"
  gsutil -m rsync -r "${input}" "${output}"
}

function send() {
  # Write into a Stackdriver log called "${NAME}-${VERSION}-${ACTION}"
  local message="${1}"
  gcloud logging write ${NAME}-${VERSION}-${ACTION} "${message}"
}

# Invoke the delete function when the script exits regardless of the reason
trap delete EXIT

# Report a successful start to Stackdriver
send 'Running the action...'
# Invoke the function specified by the ACTION environment variable
process_${ACTION}
# Report a successful completion to Stackdriver
send 'Well done.'
