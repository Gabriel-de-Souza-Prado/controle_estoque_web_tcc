"""Configuração do pytest: nenhum teste abre o PostgreSQL ou depende do .env."""
import os

# Antes de importar a aplicação: os módulos leem a configuração no import.
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["SECRET_KEY"] = "chave-exclusiva-do-pytest-com-mais-de-32-caracteres"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app


@pytest.fixture
def cliente():
    """Banco em memória novo por teste, compartilhado só com o TestClient."""
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    sessoes = sessionmaker(bind=engine)

    def banco_do_teste():
        with sessoes() as db:
            yield db

    anteriores = app.dependency_overrides.copy()
    app.dependency_overrides[get_db] = banco_do_teste
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.clear()
        app.dependency_overrides.update(anteriores)
        engine.dispose()
