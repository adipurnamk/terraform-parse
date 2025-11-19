# NOTES

## Part 1 – API service

- Language/framework: Python 3.11 + FastAPI (async), packaged with Poetry and a tiny Makefile for dev ergonomics.
- Request handling: `GenerateRequest` Pydantic model validates the nested payload (aliases for `aws-region`, `bucket-name`, `force-destroy`). Invalid ACLs are rejected early via `field_validator`.
- Render pipeline: a dedicated `TerraformRenderer` loads a Jinja2 template (`templates/s3_bucket.tf.j2`), injects metadata (timestamp, env, ACL, tags), and writes the file under a configurable output directory (`TPS_TERRAFORM_OUTPUT_DIR`).
- Configuration: `pydantic-settings` gives us typed env vars (`TPS_AWS_REGION`, `TPS_TERRAFORM_OUTPUT_DIR`). Defaults make local dev easy, while `.env` works for Docker/k8s overrides.
- Quality: pytest + httpx ensure the `/api/generate` flow creates files and returns the preview. Ruff enforces style/formatting; both run via `make test` and `make lint`.

## Part 2 – Terraform

- Issues discovered: single file mixing concerns, no tagging/validation, hard-coded names, no lifecycle protections, no clear env strategy, and public S3 bucket defaults.
- Refactor: split into local modules (`modules/network`, `modules/eks`, `modules/s3_bucket`) with well-defined inputs/outputs. Root `main.tf` stitches them together, adds default tags, and sets up space for an S3 backend + DynamoDB locking (values intentionally left blank for the operator to fill in).
- Safety: bucket lifecycle prevents accidental deletes unless `bucket_force_destroy=true`, lifecycle policy to Glacier objects, EKS logging toggles, `terraform` variable validations for environment, ACLs, and scaling numbers.
- Multi-environment: `env/{dev,staging,prod}.tfvars` capture environment-specific knobs. Recommended workflow is `terraform workspace select dev` + `-var-file=env/dev.tfvars`. Tags reflect the environment automatically.
- Remaining enhancements: integrate Terraform Cloud/Atlantis for change control, wire network module to look up VPC/subnets dynamically, add IRSA-ready module outputs for the API itself.

## Part 3 – Helm

- Problems found: duplicate front/back deployments, static selectors, no probes, no configuration, and borked routing (frontend `app` label mismatch). HPA and Service resources referenced non-existent labels.
- Fixes: rewrote the chart into a single Deployment + Service, added `_helpers.tpl` for consistent labels, readiness/liveness probes, resource requests, env wiring for the API, autoscaling toggles, and optional ServiceMonitor. Old frontend artifacts were removed.
- Tooling: introduced `helm/Makefile` with `kind-up`, `image`, `load`, `deploy`, and `lint` targets. Helm linting/templating is run via `docker run alpine/helm:3.15.2 ...` so no host install is required.
- Validation: `docker run ... helm lint .` and `helm template terraform-parse .` both succeed (see README for commands). Manual port-forward instructions included for runtime validation.

## Part 4 – System behavior & resiliency

- Load: FastAPI + Uvicorn handles concurrent writes, but Terraform rendering is file-system bound. Set resource requests/limits and horizontal pod autoscaling based on CPU to ensure responsiveness.
- Failure scenarios: S3 backend downtime would block Terraform applies; mitigate with DynamoDB locking + retries. Generated Terraform files should be persisted on a PVC/S3 for durability—today they live on the container FS, so enabling `TPS_TERRAFORM_OUTPUT_DIR=/data` + PVC would be the next step.
- Scaling strategy: HPA + readiness probes keep pods healthy. For the EKS cluster, control-plane logging is on and node group capacities are capped to prevent runaway costs; cluster-autoscaler/karpenter could be layered later.

## Part 5 – Approach & tooling

- Toolchain: Poetry, FastAPI, pytest/httpx, Ruff, Terraform 1.6, dockerized Helm 3.15, Kind (Makefile automation), and jq/curl for manual testing.
- Process: implemented the API first with TDD, refactored Terraform with modules + validations, then rebuilt the Helm chart and validated via containerized Helm since the host lacked the binary.
- AI usage: ChatGPT (GPT-5.1 Codex) assisted with brainstorming structure, drafting snippets, and double-checking Terraform/Helm syntax. All outputs were reviewed/edited by hand before inclusion.