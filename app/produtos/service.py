# Crie o arquivo service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from . import repository, schemas

def criar_equipamento(db: Session, dados: schemas.EquipamentoCriar):
    # REGRA DE NEGÓCIO 1: O DTI deve ser único na empresa
    equipamento_existente = repository.buscar_por_dti(db, dados.dti)
    if equipamento_existente:
        raise HTTPException(
            status_code=400, 
            detail=f"Já existe um equipamento cadastrado com o DTI {dados.dti}."
        )
    
    # REGRA DE NEGÓCIO 2: Validação de Status permitidos
    status_permitidos = ["Em Uso", "No Estoque", "Em Manutenção", "Descartado"]
    if dados.status not in status_permitidos:
        raise HTTPException(
            status_code=400, 
            detail=f"Status inválido. Escolha entre: {', '.join(status_permitidos)}"
        )
        
    # REGRA DE NEGÓCIO 3: Se for manutenção, exige observação
    if dados.status == "Em Manutenção" and not dados.observacao:
        raise HTTPException(
            status_code=400, 
            detail="Para equipamentos em manutenção, o campo 'observação' é obrigatório."
        )

    # Se passou por todas as regras, manda o repositório salvar!
    return repository.criar_equipamento(db, dados)