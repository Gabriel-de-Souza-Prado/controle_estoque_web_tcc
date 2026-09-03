from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from . import repository, schemas

router = APIRouter(prefix="/produtos", tags=["Produtos"])


@router.get("/", response_model=list[schemas.ProdutoPublico])
def listar(db: Session = Depends(get_db)):
    return repository.listar_produtos(db)


@router.post("/", response_model=schemas.ProdutoPublico, status_code=201)
def criar(dados: schemas.ProdutoCriar, db: Session = Depends(get_db)):
    return repository.criar_produto(db, dados)


@router.get("/{produto_id}", response_model=schemas.ProdutoPublico)
def buscar(produto_id: int, db: Session = Depends(get_db)):
    produto = repository.buscar_produto_por_id(db, produto_id)
    if not produto:
        raise HTTPException(status_code=404, detail="Produto nao encontrado")
    return produto


@router.patch("/{produto_id}", response_model=schemas.ProdutoPublico)
def atualizar(produto_id: int, dados: schemas.ProdutoAtualizar, db: Session = Depends(get_db)):
    produto = repository.buscar_produto_por_id(db, produto_id)
    if not produto:
        raise HTTPException(status_code=404, detail="Produto nao encontrado")
    return repository.atualizar_produto(db, produto, dados)


@router.delete("/{produto_id}", status_code=204)
def apagar(produto_id: int, db: Session = Depends(get_db)):
    produto = repository.buscar_produto_por_id(db, produto_id)
    if not produto:
        raise HTTPException(status_code=404, detail="Produto nao encontrado")
    repository.deletar_produto(db, produto)
    return