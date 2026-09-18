Você é um designer de Equipamento criando o protótipo navegável de uma aplicação.

CONTEXTO
Sistema de Gerenciador de estoque de equipamentos de TI. O usuário principal é O técnico ou analista de suporte que precisa controlar os ativos e hardwares da empresa.

ENTIDADE PRINCIPAL
Equipamento, com os campos:
- modelo (texto, obrigatório)
- numero_serie (texto, obrigatório)
- categoria (texto, obrigatório)
- status (texto - ex: em uso, no estoque, manutenção - obrigatório)
- observacao (texto, opcional)

Cada registro pertence a um usuário logado — Cada equipamento é cadastrado e gerenciado por um único usuário (técnico); um usuário tem muitos equipamentos sob sua gestão.

TELAS (nesta ordem)
1. Login: e-mail e senha, link para cadastro, área para mensagem de erro.
2. Cadastro de usuário: nome, e-mail e senha, com as regras visíveis.
3. Listagem de Equipamento: Busca por número de série ou modelo; filtro por status (ex: listar apenas os equipamentos "em manutenção") e por categoria, um botão de criar em destaque, e o
   estado de lista vazia, com mensagem convidando a criar o primeiro registro.
4. Formulário de criar/editar Equipamento, com as validações visíveis.
5. Detalhe de um registro, com editar e excluir (excluir pede confirmação).

STACK DE DESTINO — leia com atenção
Este protótipo é descartável, mas ele vira a especificação de um aplicativo
Flutter que consome uma API FastAPI. Projete pensando nisso:
- Use Material Design 3 como linguagem visual.
- Layout em coluna única, pensado primeiro para celular.
- Não use nada que não tenha equivalente direto em Flutter: sem grid CSS
  complexo, sem hover como única forma de revelar informação, sem sticky.
- Todo estado de tela precisa existir e estar desenhado: carregando, vazio,
  erro e sucesso.

RESTRIÇÕES
- Não crie backend, banco de dados nem autenticação real: use dados de
  exemplo fixos, inventados.
- Não invente campos que não estão na lista acima.
- Todos os textos da interface em português do Brasil.



Controle de Estoque de TI — Autoria e Estoque Global

O projeto com login e migrações, adaptado para um sistema real de Controle de Estoque de Equipamentos. Agora o equipamento ganha um dono (um usuário/técnico tem muitos equipamentos cadastrados no seu nome, garantindo auditoria). O estoque é global (todos os técnicos enxergam e gerenciam o acervo da empresa), a listagem tem busca e filtro (por dti e departamento), e o erro 422 protege a entrada de dados inconsistentes.

As alterações no banco de dados (como a adição da coluna departamento e a mudança para o PostgreSQL) entram de forma segura por migrações — o create_all não existe mais.
Como Rodar o Projeto

Instale as dependências usando o Poetry (incluindo o driver do PostgreSQL que adicionamos):
Bash

poetry install

Renomeie o arquivo env.exemplo para .env e configure suas variáveis. Lembre-se de usar o IP local para evitar travamentos no Windows:
Snippet de código

DATABASE_URL=postgresql+psycopg://postgres:SUA_SENHA@127.0.0.1:5432/WEBIII-GABRIELPRADO
SECRET_KEY=sua_senha_secreta_aqui

Gere as tabelas no banco de dados vazio (este comando aplica todas as migrações, criando as tabelas de usuarios, equipamentos e as novas colunas como dono_id e departamento):
Bash

poetry run alembic upgrade head

Por fim, suba o servidor:
Bash

poetry run uvicorn app.main:app --reload

Abra a documentação interativa e faça seus testes em: http://127.0.0.1:8000/docs.