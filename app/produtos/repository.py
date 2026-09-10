from sqlalchemy.orm import Session
from . import models, schemas


def listar_equipamentos(db: Session):
    return db.query(models.Equipamento).all() # Tirei o "s" do models.Equipamento


def buscar_equipamento_por_id(db: Session, equipamento_id: int):
    return db.query(models.Equipamento).filter(models.Equipamento.id == equipamento_id).first()


def buscar_equipamento_por_dti(db: Session, dti: str):
    return db.query(models.Equipamento).filter(models.Equipamento.dti == dti).first()


def criar_equipamento(db: Session, dados: schemas.EquipamentoCriar):
    novo_equipamento = models.Equipamento(**dados.model_dump()) # Tirei o "s" aqui
    db.add(novo_equipamento)
    db.commit()
    db.refresh(novo_equipamento)
    return novo_equipamento


def atualizar_equipamento(db: Session, equipamento: models.Equipamento, dados: schemas.EquipamentoAtualizar):
    dados_atualizacao = dados.model_dump(exclude_unset=True)
    
    for chave, valor in dados_atualizacao.items():
        setattr(equipamento, chave, valor)
        
    db.commit()
    db.refresh(equipamento)
    return equipamento


def deletar_equipamento(db: Session, equipamento: models.Equipamento):
    db.delete(equipamento)
    db.commit()