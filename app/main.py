from fastapi import FastAPI
from .database import Base, engine
from .produtos import controller as produtos_controller
from .produtos import models

# Cria as tabelas no banco de dados com base nos models importados
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do Meu Projeto", version="0.1.0")

app.include_router(produtos_controller.router)

@app.get("/")
def raiz():
    return {"status": "de pe"}