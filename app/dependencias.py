"""Composição: conecta repositories, services e a autenticação das rotas."""
from fastapi import Depends

from .produtos.repository import EquipamentoRepository, obter_equipamento_repository
from .produtos.service import EquipamentoService
from .seguranca import esquema_oauth, obter_usuario_id
from .usuarios.repository import UsuarioRepository, obter_usuario_repository
from .usuarios.service import UsuarioService


def obter_equipamento_service(
    repositorio: EquipamentoRepository = Depends(obter_equipamento_repository),
):
    return EquipamentoService(repositorio)


def obter_usuario_service(repositorio: UsuarioRepository = Depends(obter_usuario_repository)):
    return UsuarioService(repositorio)


def get_current_user(
    token: str = Depends(esquema_oauth),
    servico: UsuarioService = Depends(obter_usuario_service),
):
    return servico.buscar(obter_usuario_id(token))
