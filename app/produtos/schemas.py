from pydantic import BaseModel, Field

# Colocamos os campos comuns aqui para não ficar repetindo código
class EquipamentoBase(BaseModel):
    dti: str = Field(min_length=3)
    modelo: str = Field(min_length=2)
    numero_serie: str = Field(min_length=2)
    categoria: str = Field(min_length=2)
    status: str = Field(min_length=2)
    observacao: str | None = None  # Opcional

# Schema para CRIAR
class EquipamentoCriar(EquipamentoBase):
    pass 

# Schema para RETORNAR ao usuário (Publico)
class EquipamentoPublico(EquipamentoBase):
    id: int

    class Config:
        from_attributes = True

# Schema para ATUALIZAR (Tudo Opcional)
class EquipamentoAtualizar(BaseModel):
    dti: str | None = None
    modelo: str | None = None
    numero_serie: str | None = None
    categoria: str | None = None
    status: str | None = None
    observacao: str | None = None