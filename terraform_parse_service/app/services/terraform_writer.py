from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape

from app.config import Settings, get_settings
from app.schemas import GenerateRequest


@dataclass(slots=True)
class TerraformRenderResult:
    file_path: Path
    content: str


class TerraformRenderer:
    def __init__(self, settings: Settings | None = None):
        self.settings = settings or get_settings()
        template_dir = Path(__file__).resolve().parent.parent / "templates"
        self.env = Environment(
            loader=FileSystemLoader(str(template_dir)),
            autoescape=select_autoescape(disabled_extensions=("tf",)),
            trim_blocks=True,
            lstrip_blocks=True,
        )
        self.template = self.env.get_template("s3_bucket.tf.j2")

    def render(self, request: GenerateRequest) -> TerraformRenderResult:
        props = request.payload.properties
        bucket_resource_name = props.bucket_name.replace("-", "_")

        context = {
            "timestamp": datetime.now(tz=timezone.utc).isoformat(),
            "aws_region": props.aws_region,
            "environment": props.environment,
            "bucket_name": props.bucket_name,
            "bucket_resource_name": bucket_resource_name,
            "acl": props.acl,
            "force_destroy": props.force_destroy,
        }

        rendered = self.template.render(**context)

        output_dir = self.settings.terraform_output_dir
        output_dir.mkdir(parents=True, exist_ok=True)
        file_path = output_dir / f"s3_{bucket_resource_name}.tf"
        file_path.write_text(rendered, encoding="utf-8")

        return TerraformRenderResult(file_path=file_path, content=rendered)

