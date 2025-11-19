from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture()
def client(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> TestClient:
    monkeypatch.setenv("TPS_TERRAFORM_OUTPUT_DIR", str(tmp_path))
    return TestClient(app)


def test_generate_creates_tf_file(client: TestClient, tmp_path: Path) -> None:
    payload = {
        "payload": {
            "properties": {
                "aws-region": "us-east-1",
                "acl": "private",
                "bucket-name": "tripla-bucket",
                "environment": "dev",
            }
        }
    }

    response = client.post("/api/generate", json=payload)

    assert response.status_code == 200
    data = response.json()
    file_path = Path(data["file_path"])
    assert file_path.exists()
    assert "aws_s3_bucket" in data["preview"]
    assert "tripla-bucket" in data["preview"]

