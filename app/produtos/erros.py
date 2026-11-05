"""Recusas de negócio. A camada HTTP define os códigos de resposta."""


class EquipamentoNaoEncontrado(Exception):
    pass


class DtiJaCadastrado(Exception):
    pass


class SituacaoInvalida(Exception):
    pass
