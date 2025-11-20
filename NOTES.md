- Part 1 (API Service): Describe how you implemented the `Terraform-Parse` service. Include the framework/language you chose, how the API works, and how it translates the payload into Terraform code.

- Language/framework: Python 3.11 + FastAPI (async), packaged with Poetry and a tiny Makefile for dev ergonomics.
- Request handling: `GenerateRequest` Pydantic model validates the nested payload (aliases for `aws-region`, `bucket-name`, `force-destroy`). Invalid ACLs are rejected early via `field_validator`.
- Render pipeline: a dedicated `TerraformRenderer` loads a Jinja2 template (`templates/s3_bucket.tf.j2`), injects metadata (timestamp, env, ACL, tags), and writes the file under a configurable output directory (`TPS_TERRAFORM_OUTPUT_DIR`).
- Configuration: `pydantic-settings` gives us typed env vars (`TPS_AWS_REGION`, `TPS_TERRAFORM_OUTPUT_DIR`). Defaults make local dev easy, while `.env` works for Docker/k8s overrides.
- Quality: pytest + httpx ensure the `/api/generate` flow creates files and returns the preview. Ruff enforces style/formatting; both run via `make test` and `make lint`.

- Part 2 (Terraform): Describe the issues you found and how you approached improving them. Mention anything you think could still be enhanced.

- Findings: the original EKS module node-group misplaced, variable need to be formated, hard-coded names/versions, exposed only a single unmanaged node group, and lacked baseline security (no control-plane logs, no IRSA, public S3 ACL with no encryption/versioning). Nothing tied resources to environments, making prod vs. dev collisions likely.
- Improvements: introduced name prefixes and tag locals so every artifact is derived from `<project>-<env>`, parameterized cluster version/access/logging, switched to managed node groups with safer defaults, and hardened the static-assets bucket with encryption, versioning, and Public Access Block. All knobs are now surfaced via variables for per-env overrides.
- Still to enhance: layer/dependency in VPC/subnet creation (today we require existing networking), add managed add-ons (CoreDNS, VPC CNI, KubeProxy pinning), and bolt on automated guardrails such as AWS Config rules or OPA tests in CI.

- Part 3 (Helm): Explain the problems you encountered with the chart, how you addressed them, and how you validated your changes.
- Part 4 (System Behavior): Share your thoughts on how this setup might behave under load or in failure scenarios, and what strategies could make it more resilient in the long term.
- Part 5 (Approach & Tools): Outline the approach you took to complete the task, including any resources, tools, or methods that supported your work.