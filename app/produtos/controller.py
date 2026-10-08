from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from ..database import get_db

from ..seguranca import get_current_user 
from ..usuarios.models import Usuario 
from . import service, schemas

router = APIRouter(prefix="/equipamentos", tags=["Equipamentos"])

@router.get("/", response_model=list[schemas.EquipamentoPublico])
def listar(
    dti: str | None = None,
    departamento: str | None = None,
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user)
):
    return service.listar_equipamentos(db, dti, departamento)

@router.post("/", response_model=schemas.EquipamentoPublico, status_code=201)
def criar(
    dados: schemas.EquipamentoCriar, 
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user)
):
    return service.criar_equipamento(db, usuario_logado, dados)

@router.get("/{equipamento_id}", response_model=schemas.EquipamentoPublico)
def buscar(
    equipamento_id: int, 
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user)
):
    return service.buscar_equipamento(db, equipamento_id)

@router.patch("/{equipamento_id}", response_model=schemas.EquipamentoPublico)
def atualizar(
    equipamento_id: int,
    dados: schemas.EquipamentoAtualizar,
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user)
):
    return service.atualizar_equipamento(db, equipamento_id, dados)

@router.delete("/{equipamento_id}", status_code=204)
def apagar(
    equipamento_id: int,
    db: Session = Depends(get_db),
    usuario_logado: Usuario = Depends(get_current_user)
):
    service.deletar_equipamento(db, equipamento_id)