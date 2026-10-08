from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # <-- IMPORTANTE
from app.database import Base, engine
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

# Registrando as rotas (routers)
app.include_router(usuarios_controller.router)
app.include_router(equipamentos_controller.router)

@app.get("/")
def raiz():
    return {"status": "de pe e seguro!"} 

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)