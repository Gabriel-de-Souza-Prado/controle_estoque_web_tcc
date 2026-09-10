from fastapi import FastAPI
from app.database import Base, engine
import uvicorn

# Importando os controllers
from app.produtos import controller as equipamentos_controller
from app.usuarios import controller as usuarios_controller # <-- NOVO

# Importando os models para garantir que o banco crie as tabelas
from app.produtos import models as eq_models
from app.usuarios import models as us_models # <-- NOVO

# Cria todas as tabelas no banco de dados
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Controle de Estoque TI", version="0.1.0")

# Registrando as rotas (routers)
app.include_router(usuarios_controller.router)    # <-- NOVO: As rotas de login/cadastro
app.include_router(equipamentos_controller.router) # As rotas de equipamentos

@app.get("/")
def raiz():
    return {"status": "de pe e seguro!"} 

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)