#!/bin/bash

set -e

function process_training() {
  # Make Python be able to find the prediction package in the source directory
  export PYTHONPATH="source:${PYTHONPATH}"
  # Generate a timestamp for the current run
  local timestamp=$(date '+%Y-%m-%d')
  # Define the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Invoke training
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Copy the result to the output location in Cloud Storage
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
  # Define the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Copy the model from the input location in Cloud Storage
  load ${input} output
  # Copy the model to the output location in Cloud Storage
  save output ${output}
  # Invoke application
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Copy the result to the output location in Cloud Storage
  save output ${output}
  # Define the input location in Cloud Storage for ingesting into BigQuery
  local input=${output}/predictions.csv
  # Define the output table in BigQuery
  local output=$(echo ${NAME} | tr - _).predictions
  # Ingest the result into the output table in BigQuery
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
