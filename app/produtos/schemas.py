from pydantic import BaseModel, ConfigDict, field_validator

def _tamanho_minimo_3(valor: str):
    if len(valor.strip()) < 3:
        raise ValueError("este campo precisa ter pelo menos 3 caracteres")
    return valor.strip()

def _tamanho_minimo_2(valor: str):
    if len(valor.strip()) < 2:
        raise ValueError("este campo precisa ter pelo menos 2 caracteres")
    return valor.strip()

class EquipamentoCriar(BaseModel):
    dti: str
    modelo: str
    numero_serie: str
    categoria: str
    status: str
    departamento: str # <-- NOVO
    observacao: str | None = None

    @field_validator("dti", "departamento")
    @classmethod
    def valida_dti_e_dep(cls, v):
        return _tamanho_minimo_3(v)

    @field_validator("modelo", "numero_serie", "categoria", "status")
    @classmethod
    def valida_outros_campos(cls, v):
        return _tamanho_minimo_2(v)

class EquipamentoPublico(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    dti: str
    modelo: str
    numero_serie: str
    categoria: str
    status: str
    departamento: str # <-- NOVO
    observacao: str | None
    dono_id: int | None

class EquipamentoAtualizar(BaseModel):
    dti: str | None = None
    modelo: str | None = None
    numero_serie: str | None = None
    categoria: str | None = None
    status: str | None = None
    departamento: str | None = None # <-- NOVO
    observacao: str | None = None