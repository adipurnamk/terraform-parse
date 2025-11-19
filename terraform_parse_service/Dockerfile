FROM python:3.11-slim AS base
ENV PYTHONUNBUFFERED=1
WORKDIR /srv/app

RUN pip install --no-cache-dir uv

COPY . .
RUN uv pip install --system --no-cache .

EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
