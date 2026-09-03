from sqlalchemy import Boolean, Column, Float, Integer, String
from ..database import Base


class Produtos(Base):
    __tablename__ = "produtos"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    qtde = Column(Integer, nullable=False)
    preco = Column(Float, nullable=False)  # Adicionado pois tem no schema
    em_estoque = Column(Boolean, nullable=False, default=True)  # Corrigido para Boolean
    status = Column(String(120), nullable=False, default="ativo")  # Corrigido para String