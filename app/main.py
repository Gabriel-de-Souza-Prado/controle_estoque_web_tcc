from fastapi import FastAPI
from .produtos import controller as produtos_controller

app = FastAPI(title="API do Meu Projeto", version="0.1.0")
app.include_router(produtos_controller.router)

