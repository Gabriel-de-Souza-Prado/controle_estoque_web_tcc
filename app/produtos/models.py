from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from ..database import Base

class Equipamento(Base):  
    __tablename__ = "equipamentos" 

    id = Column(Integer, primary_key=True, index=True)
    dti = Column(String(50), unique=True, index=True, nullable=False)
    modelo = Column(String(120), nullable=False)
    numero_serie = Column(String(120), nullable=False)
    categoria = Column(String(50), nullable=False)
    status = Column(String(50), nullable=False, default="No Estoque")
    departamento = Column(String(100), nullable=False) # <-- NOVO
    observacao = Column(String(255), nullable=True)

    dono_id = Column(Integer, ForeignKey("usuarios.id", name="fk_equipamentos_dono"), nullable=True)
    dono = relationship("Usuario", back_populates="equipamentos")