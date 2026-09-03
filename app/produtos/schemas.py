from pydantic import BaseModel, Field


class ProdutoCriar(BaseModel):        
    nome: str = Field(min_length=2)
    qtde: int = Field(gt=0)  # <--- Adicionado aqui (deve ser maior que 0)
    preco: float = Field(gt=0)
    em_estoque: bool = True
    status: str = Field(min_length=2)


class ProdutoPublico(BaseModel):      
    id: int
    nome: str
    qtde: int                # <--- Adicionado aqui também
    preco: float
    em_estoque: bool
    status: str


class ProdutoAtualizar(BaseModel):    
    nome: str | None = None
    qtde: int | None = None  # <--- Opcional para atualização
    preco: float | None = None
    em_estoque: bool | None = None
    status: str | None = None