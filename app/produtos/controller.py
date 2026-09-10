from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db

# IMPORTAMOS O PORTEIRO E A CLASSE DE USUÁRIO!
from ..seguranca import get_current_user 
from ..usuarios.models import Usuario 

from . import repository, schemas

router = APIRouter(prefix="/equipamentos", tags=["Equipamentos"])

# OLHA O PORTEIRO AQUI -> usuario_logado: Usuario = Depends(get_current_user)
@router.get("/", response_model=list[schemas.EquipamentoPublico])
def listar(
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user) # <-- ROTA PROTEGIDA!
):
    return repository.listar_equipamentos(db)


@router.post("/", response_model=schemas.EquipamentoPublico, status_code=201)
def criar(
    dados: schemas.EquipamentoCriar, 
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user) # <-- ROTA PROTEGIDA!
):
    # Dica bônus: Você já sabe QUEM está criando o equipamento através da 
    # variável 'usuario_logado'. No futuro, você vai usar o 'usuario_logado.id' 
    # para amarrar o equipamento ao técnico!
    return repository.criar_equipamento(db, dados)


@router.get("/{equipamento_id}", response_model=schemas.EquipamentoPublico)
def buscar(
    equipamento_id: int, 
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user) # <-- ROTA PROTEGIDA!
):
    equipamento = repository.buscar_equipamento_por_id(db, equipamento_id)
    if not equipamento:
        raise HTTPException(status_code=404, detail="Equipamento não encontrado")
    return equipamento

# Faça o mesmo (adicione o usuario_logado = Depends...) nos endpoints de ATUALIZAR e DELETAR!