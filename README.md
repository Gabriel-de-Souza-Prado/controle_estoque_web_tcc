# Sistema de Controle de Estoque de TI

Aplicação para gerenciar equipamentos de TI, com API em FastAPI, interface em Flutter Web e banco PostgreSQL.

## Arquitetura

O projeto usa arquitetura em camadas, com Service Layer e Repository:

- **Frontend:** `screens/` → `services/` → `repositories/` → API.
- **Backend:** `controller.py` → `service.py` → `repository.py` → banco.
- **Models:** representam os dados; no backend, `schemas.py` valida os contratos de entrada e saída e `models.py` mapeia as tabelas.
- **Composição:** `main.dart` conecta os repositórios aos serviços com Provider; `dependencias.py` conecta repositories, services e autenticação no backend; `main.py` registra rotas e tratamentos HTTP dos erros de negócio.

As telas chamam os serviços. Apenas os repositórios do Flutter montam os pedidos HTTP e convertem JSON. O `EquipamentoService` obtém o token no `AuthService`, sem expô-lo às telas de equipamentos. No backend, os controllers recebem os pedidos e um service por injeção de dependência. Os serviços aplicam as regras e recebem repositories, sem sessão de banco ou HTTP. Somente os repositories usam a sessão para consultar e gravar. A rota de saúde `/` apenas informa que a API está em execução.

## Requisitos

- Python **3.14** para reproduzir as versões fixadas em `poetry.lock`. O `pyproject.toml` aceita Python 3.14 ou superior.
- Poetry para instalar as dependências de `poetry.lock`.
- PostgreSQL local, por padrão em `localhost:5432`.
- Flutter compatível com **Dart 3.13.5**; validado com Flutter **3.47.6**.
- Chrome ou Edge para executar a interface web.

O backend fica na raiz do repositório, em `app/`. A interface fica em `frontend/`.

## Executar nesta máquina

O `.env` e o ambiente `.venv` já estão preparados. Na raiz do projeto:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

Em outro terminal, dentro de `frontend/`:

```powershell
flutter run -d edge --web-port 5000
```

Ambiente local validado com Python **3.14.8** e Flutter **3.47.6** (Dart **3.13.5**). As dependências Python foram instaladas na `.venv` conforme `poetry.lock`. O grupo `dev` inclui `pytest` e `httpx`; para reproduzir o ambiente, use `poetry install --no-root`. O lock foi atualizado para incluir as ferramentas de teste da aula 14. O `.env` e a `.venv` são locais e não acompanham o repositório.

Para verificar este ambiente já preparado, na raiz:

```powershell
.\.venv\Scripts\poetry.exe run pytest
```

## Configuração local

Na raiz, copie o modelo se ainda não existir `.env`:

```powershell
Copy-Item .env.example .env
```

Preencha `DATABASE_URL` com a conexão PostgreSQL. O formato usado pelo driver instalado é:

```dotenv
DATABASE_URL=postgresql+psycopg://postgres:SUA_SENHA@localhost:5432/controle_estoque
SECRET_KEY=SUA_CHAVE_ALEATORIA
```

Gere uma chave para `SECRET_KEY` com:

```powershell
python -c "import secrets; print(secrets.token_hex(48))"
```

O `.env` local já foi reconstruído nesta máquina. Não compartilhe esse arquivo: ele contém credenciais e é ignorado pelo Git. O `.env.example` serve como modelo, sem a chave real.

O banco `controle_estoque` deve existir antes de aplicar as migrações. Se estiver preparando uma instalação nova, crie-o no pgAdmin ou no PostgreSQL:

```sql
CREATE DATABASE controle_estoque;
```

Instale as dependências e confira a situação das migrações:

```powershell
poetry install --no-root
poetry run alembic current
poetry run alembic heads
```

Para um banco novo ou com migrações pendentes, aplique:

```powershell
poetry run alembic upgrade head
```

As migrações estão em `alembic/versions/`. A aplicação não cria tabelas automaticamente ao iniciar. Um banco existente com tabelas criadas fora do Alembic precisa ser conferido antes de aplicar migrações.

## Executar a API

Na raiz:

```powershell
poetry run python -m uvicorn app.main:app --reload
```

API: http://127.0.0.1:8000. Documentação interativa: http://127.0.0.1:8000/docs.

## Executar o Flutter Web

Em outro terminal:

```powershell
cd frontend
flutter pub get
flutter run -d edge --web-port 5000
```

Para Chrome, troque `edge` por `chrome`. A porta fixa mantém a mesma origem do navegador entre execuções e permite reutilizar o token salvo. O endereço da API está em `frontend/lib/repositories/usuario_repository.dart`.

## Funcionalidades do app

O cadastro cria uma conta e faz login. A sessão fica disponível via Provider. O token é persistido pelo `TokenRepository`, com `shared_preferences`; no navegador, ele fica no armazenamento local. Antes de abrir o app, o `AuthService` tenta restaurar a sessão usando `GET /usuarios/eu`. Sair apaga o token. Os tokens vencem após 60 minutos.

O app lista, consulta, cria, edita e exclui equipamentos pelas camadas tela → `EquipamentoService` → `EquipamentoRepository`. Os pedidos protegidos enviam `Authorization: Bearer <token>`. O botão **+** abre `FormularioScreen` vazio; **Editar** abre o mesmo formulário preenchido. O formulário envia os campos DTI, modelo, número de série, categoria, status, departamento e observação. A API atribui o id e registra o usuário que cadastrou o equipamento.

A validação acontece nas duas pontas: `Form`, `TextFormField` e seus validadores conferem os campos antes do envio; a API repete as validações e aplica as regras do banco. DTI repetido retorna **409**, campos inválidos retornam **422** e status inválido ou manutenção sem observação retornam **400**. As mensagens da API aparecem na tela, mantendo os dados digitados. As regras valem também para a edição parcial por `PATCH`.

**Excluir** pede confirmação com modelo e DTI. Cancelar não envia o pedido. Depois de criar, editar ou excluir com sucesso, a tela fecha com `true`; quem a abriu busca a lista de novo, ou repassa o resultado à lista. A lista vem da API em ordem de modelo e DTI. Ao recarregar a página na rota do formulário sem uma tela anterior, o app mostra a lista.

O estoque é compartilhado: usuários autenticados podem consultar e alterar os equipamentos. `dono_id` identifica quem cadastrou; ele não restringe a visualização. As regras de empréstimo do exemplo de biblioteca não fazem parte deste domínio. A tela de movimentações ainda é provisória.

### Aula 13 — busca, filtro e avisos

A lista tem o campo **Buscar pelo DTI**. Ao pressionar Enter, o texto é enviado sem espaços nas pontas pelo caminho tela → service → repository → API. A API procura parte do DTI, sem distinguir maiúsculas e minúsculas, usando `ilike` no repository do backend. A pesquisa não filtra uma cópia local da lista. Uma resposta vazia explica o DTI procurado; Enter com o campo vazio volta à lista sem busca.

O chip **Só no estoque** envia `status=No Estoque`. Ele combina com a busca: por exemplo, `GET /equipamentos/?dti=001&status=No+Estoque`. O botão **×** limpa o texto e refaz o pedido, preservando o chip. Desligar o chip remove o filtro de status. Criar, editar, excluir ou tentar novamente mantém a busca e o filtro ativos.

`widgets/aviso.dart` centraliza os `SnackBar`: verde no sucesso e vermelho na falha. Criar e editar mostram **Equipamento salvo**; excluir mostra **Equipamento excluído**. Se a API recusar, a frase detalhada permanece no formulário/detalhe e o aviso informa a falha. Os dados digitados são preservados. Cadastro, login e saída também usam o aviso compartilhado. O aviso de sucesso permanece visível ao voltar para a lista.

### Checklist das seis funcionalidades mínimas

- [x] **Autenticação:** cadastro, login, sessão persistida e rotas protegidas. Prova: sair, tentar abrir a lista sem sessão e entrar novamente.
- [x] **CRUD:** botão +, detalhe, edição e exclusão com confirmação. Prova: criar, editar e excluir um equipamento; conferir a lista após cada ação.
- [x] **Relacionamento com o usuário:** `dono_id` vem do usuário autenticado, nunca de um campo do formulário. **Adaptação autorizada pelo professor:** estoque compartilhado entre os técnicos. Prova: criar com uma conta e consultar/editar com outra; o `dono_id` continua identificando quem cadastrou.
- [x] **Validação nas duas pontas:** validadores no formulário e schemas/regras na API. Prova: campo vazio no app, DTI repetido (409) e campo inválido no `/docs` (422); a mensagem aparece sem perder os campos.
- [x] **Busca/filtro:** busca parcial por DTI e chip Só no estoque, feitos pela API. Prova: busca com resultado, busca sem resultado, chip combinado com busca e × para limpar; conferir os parâmetros na aba Network.
- [x] **Feedback visual:** avisos verdes/vermelhos nas ações e estados de carregamento, erro e lista vazia. Prova: salvar, provocar uma recusa e excluir.

### Roteiro da demonstração e entrega

1. Entrar e criar um equipamento, por exemplo DTI `DEMO001`, com status **No Estoque**.
2. Editar o modelo e conferir o aviso verde e a lista atualizada.
3. Buscar `demo`, confirmar o pedido `?dti=demo` no Network e testar `xyz` (nenhum resultado).
4. Limpar a busca com ×. Ligar **Só no estoque**, combinar com a busca e depois desligar o chip. Um equipamento **Em Uso** deve ficar fora do filtro.
5. Tentar cadastrar o mesmo DTI para demonstrar o 409, a mensagem detalhada, o aviso vermelho e os campos preservados.
6. Entrar com outra conta e conferir o mesmo estoque compartilhado, conforme a adaptação autorizada.
7. Cancelar uma exclusão e depois confirmar outra; conferir o aviso verde, a atualização da lista e sair.
8. Executar as verificações abaixo. Na entrega, usar o link do mesmo repositório nos campos de backend e frontend.

## Rotas principais

| Operação | Método e caminho |
| --- | --- |
| Cadastrar usuário | `POST /usuarios/` |
| Login | `POST /usuarios/login` |
| Usuário da sessão | `GET /usuarios/eu` |
| Listar equipamentos | `GET /equipamentos/` |
| Buscar equipamento | `GET /equipamentos/{id}` |
| Criar equipamento | `POST /equipamentos/` |
| Editar equipamento | `PATCH /equipamentos/{id}` |
| Excluir equipamento | `DELETE /equipamentos/{id}` |

A listagem da API aceita os filtros opcionais `dti` e `departamento` (busca parcial sem distinguir maiúsculas/minúsculas) e `status` (categoria exata). Os três podem ser combinados. O Flutter usa `dti` e `status`.

## Testes

Os testes rodam sem uvicorn, navegador, PostgreSQL ou `.env`. As dependências de teste estão no grupo `dev` do Poetry.

Na raiz (o backend deste repositório fica aqui, não em uma pasta `backend/`):

```powershell
poetry install --no-root
poetry run pytest
```

Nesta máquina o Poetry está na `.venv`. Sem ativar o ambiente, os comandos equivalentes são:

```powershell
.\.venv\Scripts\poetry.exe install --no-root
.\.venv\Scripts\poetry.exe run pytest
```

Em `frontend/`:

```powershell
flutter pub get
flutter test
```

Para conferir apenas os novos arquivos da aula 14:

```powershell
# Na raiz:
poetry run pytest tests/test_endpoints.py
# Em frontend/:
flutter test test/formulario_test.dart
flutter test test/lista_test.dart
```

O backend tem **28 testes**: os 13 testes anteriores, que o pytest também reconhece, e 15 casos de endpoint da aula 14. A fixture `cliente`, em `conftest.py`, cria um SQLite em memória por teste e substitui a conexão da API. Os testes novos criam a conta e fazem login pelas rotas HTTP antes das operações; cobrem busca, CRUD, recusas, dono do token e estoque compartilhado. O PostgreSQL local não é aberto.

O Flutter tem **60 testes**, com HTTP e armazenamento de sessão simulados. `formulario_test.dart` verifica validação sem API; `lista_test.dart` verifica os dados recebidos e a lista vazia; os testes anteriores cobrem autenticação, CRUD, busca/filtro, navegação, avisos, recusas e contratos HTTP.

As duas pontas foram vistas falhando com uma regra temporariamente quebrada e passando após a restauração. Veja a [evidência e os detalhes da aula 14](docs/aula14.md).

## Análise e compilação do frontend

Dentro de `frontend/`:

```powershell
flutter analyze
flutter build web
```

## Reta final e nuvem

O [plano da aula 14](docs/aula14.md) registra o cronograma, a conferência dos 12 critérios da rubrica, a prova dos testes e os conceitos de Docker. Publicação, endereços públicos e Dockerfile ficam para a prática do encontro 15. Reserva da apresentação e demonstração ainda estão pendentes. O histórico atual tem commits em três dias diferentes; a rubrica pede quatro ou mais.
