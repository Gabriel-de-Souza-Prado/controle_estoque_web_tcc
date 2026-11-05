"""Persistência dos equipamentos: só esta camada usa a sessão de banco."""
from fastapi import Depends
from sqlalchemy.orm import Session

from ..database import get_db
from .models import Equipamento


class EquipamentoRepository:
    def __init__(self, db: Session):
        self.db = db

    def listar(self, dti=None, departamento=None, status=None):
        consulta = self.db.query(Equipamento)
        if dti:
            consulta = consulta.filter(Equipamento.dti.ilike(f"%{dti}%"))
        if departamento:
            consulta = consulta.filter(Equipamento.departamento.ilike(f"%{departamento}%"))
        if status:
            consulta = consulta.filter(Equipamento.status == status)
        return consulta.order_by(Equipamento.modelo, Equipamento.dti).all()

    def buscar(self, equipamento_id: int):
        return self.db.query(Equipamento).filter(Equipamento.id == equipamento_id).first()

    def buscar_por_dti(self, dti: str):
        return self.db.query(Equipamento).filter(Equipamento.dti == dti).first()

    def criar(self, dados: dict):
        equipamento = Equipamento(**dados)
        self.db.add(equipamento)
        self.db.commit()
        self.db.refresh(equipamento)
        return equipamento

    def atualizar(self, equipamento: Equipamento, mudancas: dict):
        for campo, valor in mudancas.items():
            setattr(equipamento, campo, valor)
        self.db.commit()
        self.db.refresh(equipamento)
        return equipamento

    def excluir(self, equipamento: Equipamento):
        self.db.delete(equipamento)
        self.db.commit()


def obter_equipamento_repository(db: Session = Depends(get_db)):
    return EquipamentoRepository(db)
