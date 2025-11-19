CHART ?= .
RELEASE ?= terraform-parse
NAMESPACE ?= terraform-parse
KIND_CLUSTER ?= tripla
IMAGE_REPO ?= terraform-parse
IMAGE_TAG ?= dev
IMAGE ?= $(IMAGE_REPO):$(IMAGE_TAG)
SERVICE_PATH ?= ../terraform_parse_service

.PHONY: kind-up kind-down image load deploy undeploy lint

kind-up:
	kind create cluster --name $(KIND_CLUSTER) --wait 120s

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

image:
	docker build -t $(IMAGE) $(SERVICE_PATH)

load: image
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER)

deploy:
	helm upgrade --install $(RELEASE) $(CHART) \
		--namespace $(NAMESPACE) --create-namespace \
		--set image.repository=$(IMAGE_REPO) \
		--set image.tag=$(IMAGE_TAG)

undeploy:
	helm uninstall $(RELEASE) --namespace $(NAMESPACE) || true

lint:
	helm lint $(CHART)

