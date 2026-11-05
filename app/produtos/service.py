"""Regras do estoque. Recebe um repositório, nunca uma sessão ou pedido HTTP."""
from .erros import DtiJaCadastrado, EquipamentoNaoEncontrado, SituacaoInvalida
from .repository import EquipamentoRepository
from .schemas import EquipamentoAtualizar, EquipamentoCriar


def validar_situacao(status: str, observacao: str | None):
    permitidos = ["Em Uso", "No Estoque", "Em Manutenção", "Descartado"]
    if status not in permitidos:
        raise SituacaoInvalida(f"Status inválido. Escolha entre: {', '.join(permitidos)}")
    if status == "Em Manutenção" and not (observacao or "").strip():
        raise SituacaoInvalida("Para manutenção, 'observação' é obrigatório.")


class EquipamentoService:
    def __init__(self, repositorio: EquipamentoRepository):
        self.repositorio = repositorio

    def listar(self, dti=None, departamento=None, status=None):
        # O estoque é compartilhado; dono_id identifica quem cadastrou.
        return self.repositorio.listar(dti, departamento, status)

    def buscar(self, equipamento_id: int):
        equipamento = self.repositorio.buscar(equipamento_id)
        if equipamento is None:
            raise EquipamentoNaoEncontrado("Equipamento não encontrado")
        return equipamento

    def criar(self, usuario_id: int, dados: EquipamentoCriar):
        if self.repositorio.buscar_por_dti(dados.dti):
            raise DtiJaCadastrado(f"Já existe um equipamento com o DTI {dados.dti}.")
        validar_situacao(dados.status, dados.observacao)
        return self.repositorio.criar({**dados.model_dump(), "dono_id": usuario_id})

    def atualizar(self, equipamento_id: int, dados: EquipamentoAtualizar):
        equipamento = self.buscar(equipamento_id)
        if dados.dti and dados.dti != equipamento.dti:
            if self.repositorio.buscar_por_dti(dados.dti):
                raise DtiJaCadastrado("Já existe outro equipamento com este DTI.")
        mudancas = dados.model_dump(exclude_unset=True)
        validar_situacao(
            mudancas.get("status", equipamento.status),
            mudancas.get("observacao", equipamento.observacao),
        )
        return self.repositorio.atualizar(equipamento, mudancas)

    def excluir(self, equipamento_id: int):
        self.repositorio.excluir(self.buscar(equipamento_id))
