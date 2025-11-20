from fastapi import APIRouter, Depends

from app.config import Settings, get_settings
from app.schemas import GenerateRequest, GenerateResponse
from app.services.terraform_writer import TerraformRenderer


router = APIRouter()


@router.get("/healthz", tags=["health"], summary="Health probe")
async def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


@router.post("/generate", response_model=GenerateResponse, tags=["terraform"], summary="Render Terraform for S3 bucket")
async def generate_terraform(
    payload: GenerateRequest,
    settings: Settings = Depends(get_settings),
) -> GenerateResponse:
    renderer = TerraformRenderer(settings=settings)
    result = renderer.render(payload)
    return GenerateResponse(file_path=str(result.file_path), preview=result.content)
