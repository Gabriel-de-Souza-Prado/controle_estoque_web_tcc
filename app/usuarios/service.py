"""Regras de conta e login, sem HTTP, SQL ou sessão de banco."""
from .. import seguranca
from .erros import CredenciaisInvalidas, EmailJaCadastrado
from .repository import UsuarioRepository
from .schemas import Token


class UsuarioService:
    def __init__(self, repositorio: UsuarioRepository):
        self.repositorio = repositorio

    def cadastrar(self, dados: dict):
        if self.repositorio.buscar_por_email(dados["email"]):
            raise EmailJaCadastrado(f"Ja existe uma conta com o e-mail {dados['email']}")
        return self.repositorio.criar({
            "nome": dados["nome"], "email": dados["email"],
            "senha_hash": seguranca.gerar_hash(dados["senha"]),
        })

    def entrar(self, email: str, senha: str):
        usuario = self.repositorio.buscar_por_email(email)
        if usuario is None or not seguranca.conferir_senha(senha, usuario.senha_hash):
            raise CredenciaisInvalidas("E-mail ou senha incorretos")
        return Token(access_token=seguranca.criar_token(usuario.id))

    def buscar(self, usuario_id: int):
        usuario = self.repositorio.buscar(usuario_id)
        if usuario is None:
            raise CredenciaisInvalidas("O usuario deste token nao existe mais")
        return usuario
