# The name of the service
name ?= example-prediction-service
# The version of the service
version ?= 2019-07-01

# The name of the project on Google Cloud Platform
project ?= example-cloud-project
# The zone for operations in Compute Engine
zone ?= europe-west1-b
# The address of Container Registry
registry ?= eu.gcr.io

# The name of the Docker image
image := ${name}
# The name of the instance excluding the action
instance := ${name}-${version}

all: log

build:
	docker rmi ${image} 2> /dev/null || true
	docker build --file container/Dockerfile --tag ${image} .
	docker tag ${image} ${registry}/${project}/${image}:${version}
	docker push ${registry}/${project}/${image}:${version}

log:
	open 'https://console.cloud.google.com/logs/viewer?project=${project}&advancedFilter=logName:%22${name}%22%20OR%0AjsonPayload.instance.name:%22${name}%22'

%-start:
	gcloud compute instances create-with-container ${instance}-$* \
		--container-image ${registry}/${project}/${image}:${version} \
		--container-env NAME=${name} \
		--container-env VERSION=${version} \
		--container-env ACTION=$* \
		--container-env ZONE=${zone} \
		--container-restart-policy never \
		--no-restart-on-failure \
		--machine-type n1-standard-1 \
		--scopes default,bigquery,compute-rw,storage-rw \
		--zone ${zone}

%-wait:
	container/wait.sh instance ${instance}-$* ${zone}

%-check:
	container/wait.sh success ${instance}-$*

.PHONY: all build log
