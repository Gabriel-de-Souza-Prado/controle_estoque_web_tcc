"""O que a aplicacao inteira usa para reconhecer quem esta' falando com ela.

Tres pecas, e nenhuma delas pertence a uma funcionalidade so' -- por isso o
arquivo mora em app/, ao lado do database.py, e nao dentro de usuarios/:

- a SENHA nunca e' guardada. Guarda-se um hash dela, e na hora do login
  compara-se hash com hash;
- o TOKEN e' o cracha' que o login entrega. Qualquer um le o que esta'
  escrito nele; ninguem consegue falsificar, porque ele vem assinado com a
  SECRET_KEY -- que so' o servidor conhece;
- obter_usuario_id confere o token; dependencias.get_current_user e' o porteiro. A rota que o pede so' roda com um
  cracha' valido na mao.
"""
import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from dotenv import load_dotenv
from fastapi.security import OAuth2PasswordBearer

from .usuarios.erros import CredenciaisInvalidas

load_dotenv()

# Sem valor padrao, de proposito: uma chave "padrao" e' uma chave publica.
SECRET_KEY = os.environ["SECRET_KEY"]
ALGORITMO = "HS256"
TOKEN_DURA_MINUTOS = 60

# Diz ao FastAPI onde fica o login. E' isto que faz o botao Authorize
# aparecer no /docs -- e, sem token no cabecalho, e' ele que responde 401.
esquema_oauth = OAuth2PasswordBearer(tokenUrl="/usuarios/login")


def gerar_hash(senha: str) -> str:
    """A senha entra, uma impressao digital dela sai. Nao ha' caminho de volta."""
    return bcrypt.hashpw(senha.encode(), bcrypt.gensalt()).decode()


def conferir_senha(senha: str, senha_hash: str) -> bool:
    """Refaz a impressao digital e compara. A senha guardada nunca aparece."""
    return bcrypt.checkpw(senha.encode(), senha_hash.encode())

def criar_token(usuario_id: int) -> str:
    """O cracha': quem e' (sub) e ate' quando vale (exp), assinado."""
    expira = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_DURA_MINUTOS)
    return jwt.encode(
        {"sub": str(usuario_id), "exp": expira}, SECRET_KEY, algorithm=ALGORITMO
    )


def obter_usuario_id(token: str) -> int:
    """Confere assinatura, validade e identificação antes de procurar a conta."""
    try:
        dados = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITMO], options={"require": ["sub", "exp"]})
        usuario_id = int(dados["sub"])
        if usuario_id <= 0:
            raise ValueError("Identificação inválida")
        return usuario_id
    except (jwt.PyJWTError, ValueError, TypeError, KeyError):
        raise CredenciaisInvalidas("Token invalido ou vencido") from None
