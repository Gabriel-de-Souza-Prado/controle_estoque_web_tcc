"""Contratos HTTP: autentica, recebe dados e delega ao service."""
from fastapi import APIRouter, Depends

from ..dependencias import get_current_user, obter_equipamento_service
from ..usuarios.models import Usuario
from . import schemas
from .service import EquipamentoService

router = APIRouter(prefix="/equipamentos", tags=["Equipamentos"])


@router.get("/", response_model=list[schemas.EquipamentoPublico])
def listar(
    dti: str | None = None,
    departamento: str | None = None,
    status: str | None = None,
    servico: EquipamentoService = Depends(obter_equipamento_service),
    usuario_logado: Usuario = Depends(get_current_user),
):
    return servico.listar(dti, departamento, status)


@router.post("/", response_model=schemas.EquipamentoPublico, status_code=201)
def criar(
    dados: schemas.EquipamentoCriar,
    servico: EquipamentoService = Depends(obter_equipamento_service),
    usuario_logado: Usuario = Depends(get_current_user),
):
    return servico.criar(usuario_logado.id, dados)


@router.get("/{equipamento_id}", response_model=schemas.EquipamentoPublico)
def buscar(
    equipamento_id: int,
    servico: EquipamentoService = Depends(obter_equipamento_service),
    usuario_logado: Usuario = Depends(get_current_user),
):
    return servico.buscar(equipamento_id)


@router.patch("/{equipamento_id}", response_model=schemas.EquipamentoPublico)
def atualizar(
    equipamento_id: int,
    dados: schemas.EquipamentoAtualizar,
    servico: EquipamentoService = Depends(obter_equipamento_service),
    usuario_logado: Usuario = Depends(get_current_user),
):
    return servico.atualizar(equipamento_id, dados)


@router.delete("/{equipamento_id}", status_code=204)
def apagar(
    equipamento_id: int,
    servico: EquipamentoService = Depends(obter_equipamento_service),
    usuario_logado: Usuario = Depends(get_current_user),
):
    servico.excluir(equipamento_id)
