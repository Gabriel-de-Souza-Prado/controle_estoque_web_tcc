from sqlalchemy.orm import Session
from fastapi import HTTPException
from . import repository, schemas
from ..usuarios.models import Usuario

def listar_equipamentos(db: Session, dti: str | None = None, departamento: str | None = None):
    # Todos veem tudo, sem filtrar por dono_id
    return repository.listar_equipamentos(db, dti, departamento)

def buscar_equipamento(db: Session, equipamento_id: int):
    equipamento = repository.buscar_equipamento_por_id(db, equipamento_id)
    if not equipamento:
        raise HTTPException(status_code=404, detail="Equipamento não encontrado")
    return equipamento

def criar_equipamento(db: Session, usuario: Usuario, dados: schemas.EquipamentoCriar):
    if repository.buscar_equipamento_por_dti(db, dados.dti):
        raise HTTPException(status_code=400, detail=f"Já existe um equipamento com o DTI {dados.dti}.")
    
    status_permitidos = ["Em Uso", "No Estoque", "Em Manutenção", "Descartado"]
    if dados.status not in status_permitidos:
        raise HTTPException(status_code=400, detail=f"Status inválido. Escolha entre: {', '.join(status_permitidos)}")
        
    if dados.status == "Em Manutenção" and not dados.observacao:
        raise HTTPException(status_code=400, detail="Para manutenção, 'observação' é obrigatório.")

    # Converte para dicionário e vincula o dono!
    dados_dit = dados.model_dump()
    dados_dit["dono_id"] = usuario.id
    
    return repository.criar_equipamento(db, dados_dit)

def atualizar_equipamento(db: Session, equipamento_id: int, dados: schemas.EquipamentoAtualizar):
    equipamento = buscar_equipamento(db, equipamento_id)
    
    if dados.dti and dados.dti != equipamento.dti:
        if repository.buscar_equipamento_por_dti(db, dados.dti):
            raise HTTPException(status_code=400, detail="Já existe outro equipamento com este DTI.")

    mudancas = dados.model_dump(exclude_unset=True)
    return repository.atualizar_equipamento(db, equipamento, mudancas)

def deletar_equipamento(db: Session, equipamento_id: int):
    equipamento = buscar_equipamento(db, equipamento_id)
    repository.deletar_equipamento(db, equipamento)