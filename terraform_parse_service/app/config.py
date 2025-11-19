from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="TPS_", env_file=".env")

    aws_region: str = Field(default="eu-west-1", description="Default AWS region")
    terraform_output_dir: Path = Field(
        default=Path("./generated"),
        description="Directory where Terraform files are written",
    )


@lru_cache()
def get_settings() -> Settings:
    return Settings()
