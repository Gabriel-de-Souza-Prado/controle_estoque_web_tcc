from pydantic import BaseModel, ConfigDict, Field, field_validator

def _tamanho_minimo_3(valor: str):
    if len(valor.strip()) < 3:
        raise ValueError("este campo precisa ter pelo menos 3 caracteres")
    return valor.strip()

def _tamanho_minimo_2(valor: str):
    if len(valor.strip()) < 2:
        raise ValueError("este campo precisa ter pelo menos 2 caracteres")
    return valor.strip()

class ValidacaoEquipamento(BaseModel):
    """Cadastro e PATCH conferem os campos enviados pelas mesmas regras."""

    @field_validator("dti", "departamento", check_fields=False)
    @classmethod
    def valida_dti_e_dep(cls, v):
        if v is None:
            raise ValueError("este campo não pode ser nulo")
        return _tamanho_minimo_3(v)

    @field_validator("modelo", "numero_serie", "categoria", "status", check_fields=False)
    @classmethod
    def valida_outros_campos(cls, v):
        if v is None:
            raise ValueError("este campo não pode ser nulo")
        return _tamanho_minimo_2(v)

    @field_validator("observacao", check_fields=False)
    @classmethod
    def limpa_observacao(cls, v):
        return (v.strip() or None) if v is not None else None


class EquipamentoCriar(ValidacaoEquipamento):
    dti: str = Field(max_length=50)
    modelo: str = Field(max_length=120)
    numero_serie: str = Field(max_length=120)
    categoria: str = Field(max_length=50)
    status: str = Field(max_length=50)
    departamento: str = Field(max_length=100)
    observacao: str | None = Field(default=None, max_length=255)

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

class EquipamentoAtualizar(ValidacaoEquipamento):
    # Ausente significa manter; nulo explícito é recusado nos campos obrigatórios.
    dti: str | None = Field(default=None, max_length=50)
    modelo: str | None = Field(default=None, max_length=120)
    numero_serie: str | None = Field(default=None, max_length=120)
    categoria: str | None = Field(default=None, max_length=50)
    status: str | None = Field(default=None, max_length=50)
    departamento: str | None = Field(default=None, max_length=100)
    observacao: str | None = Field(default=None, max_length=255)
