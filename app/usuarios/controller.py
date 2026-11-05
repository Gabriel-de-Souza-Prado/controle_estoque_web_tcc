"""Entrada HTTP das contas. Não acessa o banco nem constrói tokens."""
from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from ..dependencias import get_current_user, obter_usuario_service
from .models import Usuario
from .schemas import Token, UsuarioCriar, UsuarioPublico
from .service import UsuarioService

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


@router.post("/", response_model=UsuarioPublico, status_code=201)
def cadastrar(dados: UsuarioCriar, servico: UsuarioService = Depends(obter_usuario_service)):
    return servico.cadastrar(dados.model_dump())


@router.post("/login", response_model=Token)
def login(
    form: OAuth2PasswordRequestForm = Depends(),
    servico: UsuarioService = Depends(obter_usuario_service),
):
    return servico.entrar(form.username, form.password)


@router.get("/eu", response_model=UsuarioPublico)
def eu(usuario: Usuario = Depends(get_current_user)):
    # A dependência autentica e consulta a conta pelo UsuarioService.
    return usuario
