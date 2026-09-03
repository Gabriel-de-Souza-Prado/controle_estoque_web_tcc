from sqlalchemy.orm import Session
from . import models, schemas


def listar_produtos(db: Session):
    return db.query(models.Produtos).all()


def buscar_produto_por_id(db: Session, produto_id: int):
    return db.query(models.Produtos).filter(models.Produtos.id == produto_id).first()


def criar_produto(db: Session, dados: schemas.ProdutoCriar):
    novo_produto = models.Produtos(**dados.model_dump())
    db.add(novo_produto)
    db.commit()
    db.refresh(novo_produto)
    return novo_produto


def atualizar_produto(db: Session, produto: models.Produtos, dados: schemas.ProdutoAtualizar):
    dados_atualizacao = dados.model_dump(exclude_unset=True)
    for chave, valor in dados_atualizacao.items():
        setattr(produto, chave, valor)
    db.commit()
    db.refresh(produto)
    return produto


def deletar_produto(db: Session, produto: models.Produtos):
    db.delete(produto)
    db.commit()