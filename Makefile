# The name of the product
name ?= example-prediction
# The version of the product
version ?= 2019-00-00

# The name of the project on Google Cloud Platform
project ?= example-project
# The zone for operations in Google Compute Engine
zone ?= europe-west1-b
# The address of Google Container Registry
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

define action
$(1)-check:
	container/wait.sh success ${instance}-$(1)

$(1)-start:
	gcloud compute instances create-with-container ${instance}-$(1) \
		--container-image ${registry}/${project}/${image}:${version} \
		--container-env NAME=${name} \
		--container-env VERSION=${version} \
		--container-env ACTION=$(1) \
		--container-env ZONE=${zone} \
		--container-restart-policy never \
		--machine-type n1-standard-1 \
		--no-restart-on-failure \
		--scopes default,bigquery,storage-rw,https://www.googleapis.com/auth/compute \
		--zone ${zone}

$(1)-wait:
	container/wait.sh instance ${instance}-$(1) ${zone}

.PHONY: $(1)-check $(1)-start $(1)-wait
endef

$(eval $(call action,training))
$(eval $(call action,application))

.PHONY: all build log
