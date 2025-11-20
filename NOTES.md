- Part 1 (API Service): Describe how you implemented the `Terraform-Parse` service. Include the framework/language you chose, how the API works, and how it translates the payload into Terraform code.

- Language/framework: Python 3.11 + FastAPI (async), packaged with Poetry and a tiny Makefile for dev ergonomics.
- Request handling: `GenerateRequest` Pydantic model validates the nested payload (aliases for `aws-region`, `bucket-name`, `force-destroy`). Invalid ACLs are rejected early via `field_validator`.
- Render pipeline: a dedicated `TerraformRenderer` loads a Jinja2 template (`templates/s3_bucket.tf.j2`), injects metadata (timestamp, env, ACL, tags), and writes the file under a configurable output directory (`TPS_TERRAFORM_OUTPUT_DIR`).
- Configuration: `pydantic-settings` gives us typed env vars (`TPS_AWS_REGION`, `TPS_TERRAFORM_OUTPUT_DIR`). Defaults make local dev easy, while `.env` works for Docker/k8s overrides.
- Quality: pytest + httpx ensure the `/api/generate` flow creates files and returns the preview. Ruff enforces style/formatting; both run via `make test` and `make lint`.

- Part 2 (Terraform): Describe the issues you found and how you approached improving them. Mention anything you think could still be enhanced.
- Part 3 (Helm): Explain the problems you encountered with the chart, how you addressed them, and how you validated your changes.
- Part 4 (System Behavior): Share your thoughts on how this setup might behave under load or in failure scenarios, and what strategies could make it more resilient in the long term.
- Part 5 (Approach & Tools): Outline the approach you took to complete the task, including any resources, tools, or methods that supported your work.