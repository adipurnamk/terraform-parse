# Terraform-Parse Solution

This repository now contains a working implementation of a Terraform rendering API, hardened Terraform infrastructure configuration, and a production-ready Helm chart for shipping the service to Kubernetes.

## Repository layout

- `terraform_parse_service/` – FastAPI service that turns JSON payloads into Terraform `.tf` files.
- `terraform/` – Modularized Terraform stack with EKS + S3, environment tfvars, and guardrails.
- `helm/` – Single-service Helm chart with probes, autoscaling toggles, and Kind helper Makefile.
- `NOTES.md` – Deep dive into design decisions, trade-offs, and follow-up ideas.

## Prerequisites

- Python 3.11+, [Poetry](https://python-poetry.org/) 1.7+
- Docker + Kind (or any Kubernetes cluster)
- Terraform 1.6+
- AWS credentials that can create EKS/S3 resources (for real applies)
- Helm 3 (can be run via the provided Docker invocation)

## Terraform Parse API service

```bash
cd terraform-parse/terraform_parse_service
make install        # poetry install --sync
make run            # uvicorn app.main:app --reload --port 8080
```

Sample request:

```bash
curl -X POST http://localhost:8080/api/generate -H 'Content-Type: application/json' -d '{
  "payload": {
    "properties": {
      "aws-region": "eu-west-1",
      "bucket-name": "tripla-bucket",
      "acl": "private",
      "environment": "dev"
    }
  }
}'
```

The response returns the file path under `./generated/` plus a Terraform preview. All defaults can be overridden via env vars that start with `TPS_` (see `app/config.py`).

### Tests & lint

```bash
cd terraform-parse/terraform_parse_service
make lint
make test
```

## Terraform workflow (multi-env)

The Terraform code was broken into local modules (`modules/network`, `modules/eks`, `modules/s3_bucket`) and hardened with tagging, lifecycle policies, input validation, and an S3 backend stub. Environment overlays live in `terraform/env/`.

```bash
cd terraform-parse/terraform
cp env/dev.tfvars myenv.tfvars              # adjust IDs/ARNs before applying
terraform init                              # configure backend "s3" before first init
terraform workspace select dev || terraform workspace new dev
terraform plan -var-file=myenv.tfvars
terraform apply -var-file=myenv.tfvars
```

Key notes:

- `env/*.tfvars` hold region, VPC, subnet, and bucket settings for `dev`, `staging`, and `prod`.
- The backend block is present but empty—fill in bucket, key, region, and DynamoDB table per environment before running `terraform init`.
- Guardrails: lifecycle `prevent_destroy` on the bucket (unless `bucket_force_destroy=true`), validations on environment/ACL/node sizes, default tags, and control-plane log toggles.

## Helm deployment

The Helm chart now represents only the Terraform-Parse API (single Deployment + Service + optional HPA/ServiceMonitor). Use Dockerized Helm + Kind for a local walkthrough:

```bash
cd terraform-parse/helm
make kind-up                             # creates kind cluster named "tripla"
make image IMAGE_REPO=terraform-parse IMAGE_TAG=dev
make load                                # loads the image into kind
make deploy                              # helm upgrade --install ...

# Validate
docker run --rm -v $(pwd):/charts -w /charts alpine/helm:3.15.2 lint .
kubectl port-forward svc/terraform-parse-tripla-apps 8080:8080
curl localhost:8080/api/healthz
```

Toggle autoscaling and ServiceMonitor features via `values.yaml`:

```yaml
autoscaling:
  enabled: true
metrics:
  enabled: true
  scrapePort: http
  path: /metrics
```

## Validation checklist

- `make test` succeeds for the FastAPI service (pytest + httpx).
- `docker run ... helm lint` and `helm template` run clean.
- Terraform code passes `terraform validate` (after backend configuration) and supports environment-specific tfvars/workspaces.

Refer to `NOTES.md` for a detailed explanation of the design choices, additional improvements to consider, and how AI assisted in the workflow.
