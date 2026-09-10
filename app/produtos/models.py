from sqlalchemy import Column, Integer, String
from ..database import Base

class Equipamento(Base):  # <-- SINGULAR AQUI
    __tablename__ = "equipamentos" # <-- PLURAL AQUI (nome da tabela no banco)

    id = Column(Integer, primary_key=True, index=True)
    dti = Column(String(50), unique=True, index=True, nullable=False)
    modelo = Column(String(120), nullable=False)
    numero_serie = Column(String(120), nullable=False)
    categoria = Column(String(50), nullable=False)
    status = Column(String(50), nullable=False, default="No Estoque")
    observacao = Column(String(255), nullable=True)