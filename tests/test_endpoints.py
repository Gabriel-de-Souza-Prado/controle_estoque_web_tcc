"""Aula 14: prepara, faz o pedido HTTP e confere a regra de negócio.

Cadastro, hash, login, JWT, controllers, services, repositories e banco são
reais. Apenas o cliente e o banco são exclusivos dos testes.
"""
from datetime import datetime, timedelta, timezone

import jwt
import pytest

from app.seguranca import ALGORITMO, SECRET_KEY

EQUIPAMENTO = {
    "dti": "DTI001", "modelo": "Notebook Dell", "numero_serie": "SERIE001",
    "categoria": "Notebook", "status": "No Estoque", "departamento": "Suporte",
}


def entrar(cliente, email="ana@example.com"):
    conta = cliente.post("/usuarios/", json={
        "nome": "Técnico Teste", "email": email, "senha": "segredo123",
    })
    assert conta.status_code == 201
    assert "senha" not in conta.json() and "senha_hash" not in conta.json()
    resposta = cliente.post("/usuarios/login", data={
        "username": email, "password": "segredo123",
    })
    assert resposta.status_code == 200
    return {"Authorization": "Bearer " + resposta.json()["access_token"]}


def criar(cliente, headers, **mudancas):
    resposta = cliente.post("/equipamentos/", json={**EQUIPAMENTO, **mudancas}, headers=headers)
    assert resposta.status_code == 201
    return resposta.json()


def test_criar_devolve_201_com_dti_e_dono_do_token(cliente):
    ana = entrar(cliente)
    usuario = cliente.get("/usuarios/eu", headers=ana).json()
    # Mesmo com um dono inventado no JSON, a API usa a identidade do token.
    item = criar(cliente, ana, dono_id=999)
    assert item["dti"] == "DTI001"
    assert item["dono_id"] == usuario["id"]


def test_sem_token_a_api_recusa(cliente):
    resposta = cliente.get("/equipamentos/")
    assert resposta.status_code == 401


def test_outra_conta_ve_o_estoque_sem_mudar_quem_cadastrou(cliente):
    # Adaptação autorizada: técnicos trabalham no mesmo estoque.
    ana = entrar(cliente)
    bruno = entrar(cliente, "bruno@example.com")
    item = criar(cliente, ana)
    lista = cliente.get("/equipamentos/", headers=bruno)
    assert lista.status_code == 200
    assert [registro["id"] for registro in lista.json()] == [item["id"]]
    assert lista.json()[0]["dono_id"] == item["dono_id"]


def test_editar_muda_modelo_e_persiste_no_detalhe(cliente):
    ana = entrar(cliente)
    item = criar(cliente, ana)
    resposta = cliente.patch(f"/equipamentos/{item['id']}", json={"modelo": "Notebook Lenovo"}, headers=ana)
    assert resposta.status_code == 200
    assert resposta.json()["modelo"] == "Notebook Lenovo"
    detalhe = cliente.get(f"/equipamentos/{item['id']}", headers=ana)
    assert detalhe.json()["modelo"] == "Notebook Lenovo"


def test_excluir_remove_da_lista_e_do_detalhe(cliente):
    ana = entrar(cliente)
    item = criar(cliente, ana)
    resposta = cliente.delete(f"/equipamentos/{item['id']}", headers=ana)
    assert resposta.status_code == 204
    assert resposta.content == b""
    assert cliente.get("/equipamentos/", headers=ana).json() == []
    assert cliente.get(f"/equipamentos/{item['id']}", headers=ana).status_code == 404


def test_equipamento_inexistente_devolve_404(cliente):
    resposta = cliente.get("/equipamentos/999", headers=entrar(cliente))
    assert resposta.status_code == 404


def test_dti_repetido_devolve_409_sem_duplicar_registro(cliente):
    ana = entrar(cliente)
    criar(cliente, ana)
    resposta = cliente.post("/equipamentos/", json=EQUIPAMENTO, headers=ana)
    assert resposta.status_code == 409
    assert "DTI" in resposta.json()["detail"]
    assert len(cliente.get("/equipamentos/", headers=ana).json()) == 1


def test_busca_devolve_so_o_dti_que_combina(cliente):
    ana = entrar(cliente)
    criar(cliente, ana)
    criar(cliente, ana, dti="OUTRO002", modelo="Monitor LG")
    resposta = cliente.get("/equipamentos/", params={"dti": "dti0"}, headers=ana)
    assert resposta.status_code == 200
    assert [item["dti"] for item in resposta.json()] == ["DTI001"]


def test_senha_errada_devolve_401(cliente):
    entrar(cliente)
    resposta = cliente.post("/usuarios/login", data={
        "username": "ana@example.com", "password": "senha-errada",
    })
    assert resposta.status_code == 401


def test_dti_invalido_devolve_422_sem_gravar(cliente):
    ana = entrar(cliente)
    resposta = cliente.post("/equipamentos/", json={**EQUIPAMENTO, "dti": " "}, headers=ana)
    assert resposta.status_code == 422
    assert cliente.get("/equipamentos/", headers=ana).json() == []


@pytest.mark.parametrize("sub", [None, "nao-e-um-id", "0", "-1"])
def test_token_com_identificacao_invalida_devolve_401(cliente, sub):
    token = jwt.encode({
        "sub": sub, "exp": datetime.now(timezone.utc) + timedelta(minutes=1),
    }, SECRET_KEY, algorithm=ALGORITMO)
    resposta = cliente.get("/equipamentos/", headers={"Authorization": "Bearer " + token})
    assert resposta.status_code == 401


def test_token_vencido_devolve_401(cliente):
    token = jwt.encode({
        "sub": "1", "exp": datetime.now(timezone.utc) - timedelta(minutes=1),
    }, SECRET_KEY, algorithm=ALGORITMO)
    resposta = cliente.get("/equipamentos/", headers={"Authorization": "Bearer " + token})
    assert resposta.status_code == 401
