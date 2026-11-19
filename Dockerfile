FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=false

WORKDIR /app

COPY pyproject.toml poetry.lock ./
RUN pip install --no-cache-dir poetry==2.5.1 \
    && poetry install --only main --no-root --no-interaction

COPY . .

CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
