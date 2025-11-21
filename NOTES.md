- Part 1 (API Service): Describe how you implemented the `Terraform-Parse` service. Include the framework/language you chose, how the API works, and how it translates the payload into Terraform code.

- Language/framework: Python 3.11 + FastAPI (async), packaged with Poetry and a tiny Makefile for dev ergonomics.
- Request handling: `GenerateRequest` Pydantic model validates the nested payload (aliases for `aws-region`, `bucket-name`, `force-destroy`). Invalid ACLs are rejected early via `field_validator`.
- Render pipeline: a dedicated `TerraformRenderer` loads a Jinja2 template (`templates/s3_bucket.tf.j2`), injects metadata (timestamp, env, ACL, tags), and writes the file under a configurable output directory (`TPS_TERRAFORM_OUTPUT_DIR`).
- Configuration: `pydantic-settings` gives us typed env vars (`TPS_AWS_REGION`, `TPS_TERRAFORM_OUTPUT_DIR`). Defaults make local dev easy, while `.env` works for Docker/k8s overrides.
- Quality: pytest + httpx ensure the `/api/generate` flow creates files and returns the preview. Ruff enforces style/formatting; both run via `make test` and `make lint`.

- Part 2 (Terraform): Describe the issues you found and how you approached improving them. Mention anything you think could still be enhanced.

- Findings: the original EKS module hard-coded names/versions, exposed only a single unmanaged node group, and lacked baseline security (no control-plane logs, no IRSA, public S3 ACL with no encryption/versioning). Nothing tied resources to environments, making prod vs. dev collisions likely.
- Improvements: introduced name prefixes and tag locals so every artifact is derived from `<project>-<env>`, parameterized cluster version/access/logging, switched to managed node groups with safer defaults, and hardened the static-assets bucket with encryption, versioning, and Public Access Block. All knobs are now surfaced via variables for per-env overrides.
- Still to enhance: layer in VPC/subnet creation (today we require existing networking), add managed add-ons (CoreDNS, VPC CNI, KubeProxy pinning), and bolt on automated guardrails such as AWS Config rules or OPA tests in CI.

- Part 3 (Helm): Explain the problems you encountered with the chart, how you addressed them, and how you validated your changes.

- Problems Encountered:
  - **Label Mismatch**: Frontend deployment labels (`app: frontend-app`) didn't match service selectors (`app: frontend`), causing routing failures.
  - **Hardcoded Configuration**: Replicas, images, and ports were hardcoded, making the chart inflexible.
  - **Port Mismatches**: Container ports were missing or inconsistent with service target ports.
  - **Generic Structure**: The chart deployed generic frontend/backend services instead of the specific `terraform-parse` application.
  - **Missing Resources**: No resource requests/limits were defined, preventing HPA from functioning correctly.

- Solutions:
  - **Refactored Templates**: Created a unified `terraform-parse` deployment/service using `_helpers.tpl` for consistent `app.kubernetes.io/*` labels.
  - **Full Configuration**: Moved all hardcoded values to `values.yaml` (images, ports, resources, replicas).
  - **Resource Management**: Added resource requests/limits and configured a conditional HPA with CPU/memory metrics.
  - **Health Checks**: Implemented liveness and readiness probes targeting `/api/healthz`.

- Validation:
  - `helm lint` now passes (fixed "mapping values not allowed" errors).
  - `helm template` confirms correct label matching and value substitution.
  - Verified port definitions and resource rendering in generated manifests.


- Part 4 (System Behavior): Share your thoughts on how this setup might behave under load or in failure scenarios, and what strategies could make it more resilient in the long term.


- Part 5 (Approach & Tools): Outline the approach you took to complete the task, including any resources, tools, or methods that supported your work.