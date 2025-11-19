from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field, field_validator


class BucketProperties(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    aws_region: str = Field(alias="aws-region")
    acl: str
    bucket_name: str = Field(alias="bucket-name")
    environment: str = "dev"
    force_destroy: bool = Field(default=False, alias="force-destroy")

    @field_validator("acl")
    def validate_acl(cls, value: str) -> str:
        allowed = {"private", "public-read", "public-read-write", "authenticated-read"}
        if value not in allowed:
            raise ValueError(f"Unsupported ACL '{value}'. Allowed: {', '.join(sorted(allowed))}")
        return value


class Payload(BaseModel):
    properties: BucketProperties


class GenerateRequest(BaseModel):
    payload: Payload


class GenerateResponse(BaseModel):
    file_path: str
    preview: str

