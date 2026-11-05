from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware # <-- IMPORTANTE
from fastapi.responses import JSONResponse
from app.produtos.erros import DtiJaCadastrado, EquipamentoNaoEncontrado, SituacaoInvalida
from app.usuarios.erros import CredenciaisInvalidas, EmailJaCadastrado
import uvicorn

# Importando os controllers
from app.produtos import controller as equipamentos_controller
from app.usuarios import controller as usuarios_controller

app = FastAPI(title="Controle de Estoque TI", version="0.1.0")

# <-- ADICIONE ESTE BLOCO PARA LIBERAR O FLUTTER WEB -->
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Permite o Flutter Web acessar a API
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(EquipamentoNaoEncontrado)
def equipamento_nao_encontrado(request: Request, erro: EquipamentoNaoEncontrado):
    return JSONResponse(status_code=404, content={"detail": str(erro)})


@app.exception_handler(DtiJaCadastrado)
def dti_ja_cadastrado(request: Request, erro: DtiJaCadastrado):
    return JSONResponse(status_code=409, content={"detail": str(erro)})


@app.exception_handler(SituacaoInvalida)
def situacao_invalida(request: Request, erro: SituacaoInvalida):
    return JSONResponse(status_code=400, content={"detail": str(erro)})

# Traduz os erros do dominio (usuarios/erros.py) para HTTP. Sem isto, eles
# viram 500 -- e o app nao consegue distinguir "e-mail repetido" (409) de
# "token vencido" (401), que e' o que ele precisa para decidir o que mostrar.
@app.exception_handler(EmailJaCadastrado)
def email_ja_cadastrado(request: Request, erro: EmailJaCadastrado):
    return JSONResponse(status_code=409, content={"detail": str(erro)})


@app.exception_handler(CredenciaisInvalidas)
def credenciais_invalidas(request: Request, erro: CredenciaisInvalidas):
    return JSONResponse(
        status_code=401,
        content={"detail": str(erro)},
        headers={"WWW-Authenticate": "Bearer"},
    )


# Registrando as rotas (routers)
app.include_router(usuarios_controller.router)
app.include_router(equipamentos_controller.router)

@app.get("/")
def raiz():
    return {"status": "de pe e seguro!"} 

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
