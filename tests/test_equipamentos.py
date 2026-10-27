"""Contratos da API usando um banco temporário, sem acessar o PostgreSQL local."""
import os
import unittest

# Definidos antes do import da aplicação; load_dotenv não substitui estes valores.
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["SECRET_KEY"] = "chave-exclusiva-dos-testes-sem-uso-no-ambiente-local"

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.seguranca import criar_token
from app.usuarios.models import Usuario


class EquipamentosTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
        )
        Base.metadata.create_all(self.engine)
        self.sessoes = sessionmaker(bind=self.engine)
        with self.sessoes() as db:
            db.add(Usuario(id=1, nome="Ana", email="ana@estoque.com", senha_hash="nao-usado"))
            db.commit()

        def banco_de_teste():
            with self.sessoes() as db:
                yield db

        app.dependency_overrides[get_db] = banco_de_teste
        self.client = TestClient(app)
        self.headers = {"Authorization": f"Bearer {criar_token(1)}"}
        self.dados = {
            "dti": "DTI001", "modelo": "Notebook Dell", "numero_serie": "SERIE001",
            "categoria": "Notebook", "status": "No Estoque", "departamento": "Suporte",
            "observacao": None,
        }

    def tearDown(self):
        self.client.close()
        app.dependency_overrides.clear()
        self.engine.dispose()

    def criar(self, **mudancas):
        return self.client.post("/equipamentos/", json={**self.dados, **mudancas}, headers=self.headers)

    def atualizar(self, equipamento_id, **mudancas):
        return self.client.patch(f"/equipamentos/{equipamento_id}", json=mudancas, headers=self.headers)

    def test_crud_completo(self):
        criado = self.criar()
        self.assertEqual(criado.status_code, 201)
        item = criado.json()
        self.assertEqual(item["dono_id"], 1)
        equipamento_id = item["id"]
        atualizado = self.atualizar(equipamento_id, modelo="Notebook Lenovo")
        self.assertEqual(atualizado.status_code, 200)
        self.assertEqual(atualizado.json()["modelo"], "Notebook Lenovo")
        self.assertEqual(atualizado.json()["dti"], "DTI001")
        lista = self.client.get("/equipamentos/", headers=self.headers)
        self.assertEqual(lista.json()[0]["modelo"], "Notebook Lenovo")
        apagado = self.client.delete(f"/equipamentos/{equipamento_id}", headers=self.headers)
        self.assertEqual(apagado.status_code, 204)
        self.assertEqual(apagado.content, b"")
        self.assertEqual(self.client.get("/equipamentos/", headers=self.headers).json(), [])

    def test_rotas_exigem_token(self):
        for metodo, url in [("get", "/equipamentos/"), ("get", "/equipamentos/1"),
                            ("post", "/equipamentos/"), ("patch", "/equipamentos/1"),
                            ("delete", "/equipamentos/1")]:
            with self.subTest(metodo=metodo):
                self.assertEqual(getattr(self.client, metodo)(url).status_code, 401)

    def test_dti_duplicado_no_cadastro_e_na_edicao(self):
        primeiro = self.criar().json()
        self.assertEqual(self.criar().status_code, 409)
        segundo = self.criar(dti="DTI002").json()
        self.assertEqual(self.atualizar(segundo["id"], dti=primeiro["dti"]).status_code, 409)
        self.assertEqual(self.atualizar(primeiro["id"], dti=primeiro["dti"]).status_code, 200)

    def test_campos_invalidos_sao_recusados_em_ambas_as_operacoes(self):
        equipamento_id = self.criar().json()["id"]
        for campo in ["dti", "modelo", "numero_serie", "categoria", "status", "departamento"]:
            for valor in ["", " ", "A", None]:
                with self.subTest(campo=campo, valor=valor):
                    self.assertEqual(self.criar(**{campo: valor}).status_code, 422)
                    self.assertEqual(self.atualizar(equipamento_id, **{campo: valor}).status_code, 422)

    def test_limites_do_banco_sao_validados_antes_de_gravar(self):
        equipamento_id = self.criar().json()["id"]
        for campo, limite in {"dti": 50, "modelo": 120, "numero_serie": 120, "categoria": 50,
                              "status": 50, "departamento": 100, "observacao": 255}.items():
            with self.subTest(campo=campo):
                self.assertEqual(self.criar(**{campo: "X" * (limite + 1)}).status_code, 422)
                self.assertEqual(self.atualizar(equipamento_id, **{campo: "X" * (limite + 1)}).status_code, 422)

    def test_status_invalido_na_criacao_e_edicao(self):
        self.assertEqual(self.criar(status="Inexistente").status_code, 400)
        equipamento_id = self.criar().json()["id"]
        self.assertEqual(self.atualizar(equipamento_id, status="Inexistente").status_code, 400)

    def test_manutencao_exige_observacao_inclusive_em_patch_parcial(self):
        self.assertEqual(self.criar(status="Em Manutenção", observacao="  ").status_code, 400)
        equipamento_id = self.criar().json()["id"]
        self.assertEqual(self.atualizar(equipamento_id, status="Em Manutenção").status_code, 400)
        atualizado = self.atualizar(equipamento_id, status="Em Manutenção", observacao="Trocar fonte")
        self.assertEqual(atualizado.status_code, 200)
        for observacao in [None, "", "  "]:
            self.assertEqual(self.atualizar(equipamento_id, observacao=observacao).status_code, 400)
        self.assertEqual(self.atualizar(equipamento_id, modelo="Modelo novo").status_code, 200)

    def test_observacao_pode_ser_limpa_fora_da_manutencao(self):
        equipamento_id = self.criar(observacao="Nota antiga").json()["id"]
        resposta = self.atualizar(equipamento_id, observacao=None)
        self.assertEqual(resposta.status_code, 200)
        self.assertIsNone(resposta.json()["observacao"])

    def test_id_inexistente_retorna_404(self):
        self.assertEqual(self.client.get("/equipamentos/999", headers=self.headers).status_code, 404)
        self.assertEqual(self.atualizar(999, modelo="Modelo novo").status_code, 404)
        self.assertEqual(self.client.delete("/equipamentos/999", headers=self.headers).status_code, 404)

    def test_lista_ordenada_e_filtros_preservados(self):
        self.criar(dti="ZZZ001", modelo="Zebra")
        self.criar(dti="AAA001", modelo="Alpha", departamento="Financeiro")
        lista = self.client.get("/equipamentos/", headers=self.headers).json()
        self.assertEqual([item["modelo"] for item in lista], ["Alpha", "Zebra"])
        filtrados = self.client.get("/equipamentos/?departamento=fin&dti=AAA", headers=self.headers).json()
        self.assertEqual([item["dti"] for item in filtrados], ["AAA001"])


if __name__ == "__main__":
    unittest.main()
