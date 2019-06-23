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
  gsutil -m rsync -r "${1}" output
}

function save() {
  gsutil -m rsync -r output "${1}"
}

function process_application() {
  source activate py3env
  export PYTHONPATH="source:${PYTHONPATH}"
  local stamp=$(date '+%Y-%m-%d')
  local input=$(gsutil ls gs://${NAME}/${VERSION}/training 2> /dev/null | sort | tail -1)
  local output="gs://${NAME}/${VERSION}/application/${stamp}"
  load "${input}"
  save "${output}"
  python -m prediction.main --action application --config configs/application.json
  save "${output}"
}

function process_training() {
  source activate py3env
  export PYTHONPATH="source:${PYTHONPATH}"
  local stamp=$(date '+%Y-%m-%d')
  local output="gs://${NAME}/${VERSION}/training/${stamp}"
  python -m prediction.main --action training --config configs/training.json
  save "${output}"
}

trap delete EXIT
info "Running action '${ACTION}'..."
"process_${ACTION}"
info 'Well done.'
