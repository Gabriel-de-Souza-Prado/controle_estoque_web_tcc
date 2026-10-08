from sqlalchemy.orm import Session
from . import models

def listar_equipamentos(db: Session, dti: str | None = None, departamento: str | None = None):
    consulta = db.query(models.Equipamento)
    
    # Filtros opcionais montados aos poucos (igual o professor fez)
    if dti:
        consulta = consulta.filter(models.Equipamento.dti.ilike(f"%{dti}%"))
    if departamento:
        consulta = consulta.filter(models.Equipamento.departamento.ilike(f"%{departamento}%"))
        
    return consulta.all()

def buscar_equipamento_por_id(db: Session, equipamento_id: int):
    return db.query(models.Equipamento).filter(models.Equipamento.id == equipamento_id).first()

def buscar_equipamento_por_dti(db: Session, dti: str):
    return db.query(models.Equipamento).filter(models.Equipamento.dti == dti).first()

def criar_equipamento(db: Session, dados: dict):
    # Recebe um dict agora, pois o service vai anexar o dono_id
    novo_equipamento = models.Equipamento(**dados)
    db.add(novo_equipamento)
    db.commit()
    db.refresh(novo_equipamento)
    return novo_equipamento

def atualizar_equipamento(db: Session, equipamento: models.Equipamento, mudancas: dict):
    for chave, valor in mudancas.items():
        setattr(equipamento, chave, valor)
    db.commit()
    db.refresh(equipamento)
    return equipamento

def deletar_equipamento(db: Session, equipamento: models.Equipamento):
    db.delete(equipamento)
    db.commit()