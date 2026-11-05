"""Persistência dos usuários, com uma sessão por requisição."""
from fastapi import Depends
from sqlalchemy.orm import Session

from ..database import get_db
from .models import Usuario


class UsuarioRepository:
    def __init__(self, db: Session):
        self.db = db

    def buscar(self, usuario_id: int):
        return self.db.query(Usuario).filter(Usuario.id == usuario_id).first()

    def buscar_por_email(self, email: str):
        return self.db.query(Usuario).filter(Usuario.email == email).first()

    def criar(self, dados: dict):
        usuario = Usuario(**dados)
        self.db.add(usuario)
        self.db.commit()
        self.db.refresh(usuario)
        return usuario


def obter_usuario_repository(db: Session = Depends(get_db)):
    return UsuarioRepository(db)
