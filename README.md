# Sistema de Controle de Estoque de TI

Aplicação para gerenciar equipamentos de TI, com API em FastAPI, interface em Flutter Web e banco PostgreSQL.

## Arquitetura

O projeto usa arquitetura em camadas, com Service Layer e Repository:

- **Frontend:** `screens/` → `services/` → `repositories/` → API.
- **Backend:** `controller.py` → `service.py` → `repository.py` → banco.
- **Models:** representam os dados; no backend, `schemas.py` valida os contratos de entrada e saída e `models.py` mapeia as tabelas.
- **Composição:** `main.dart` conecta os repositórios aos serviços com Provider; `main.py` registra as rotas e os tratamentos de erro da API.

As telas chamam os serviços. Apenas os repositórios do Flutter montam os pedidos HTTP e convertem JSON. O `EquipamentoService` obtém o token no `AuthService`, sem expô-lo às telas de equipamentos. No backend, os controllers recebem os pedidos, os serviços aplicam as regras e os repositórios consultam e gravam no banco.

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

Esta máquina tem Python 3.15. O ambiente local usa dependências compatíveis com essa versão, dentro dos intervalos declarados em `pyproject.toml`. Algumas versões binárias antigas de `poetry.lock` não têm distribuição para Python 3.15 no Windows; para reproduzir exatamente aquele arquivo, use Python 3.14. O arquivo de lock original foi preservado.

Para verificar este ambiente já preparado, na raiz:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
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

A listagem da API também aceita os filtros opcionais `dti` e `departamento`.

## Verificação

Dentro de `frontend/`:

```powershell
flutter analyze
flutter test
flutter build web
```

Os testes usam HTTP simulado e armazenamento de sessão simulado. Conferem autenticação, listagem, detalhe, formulário, validação, cancelamento, atualização da lista, confirmação e recusas da API, além dos contratos HTTP dos repositórios. Não precisam do servidor ligado.

Os testes do backend usam `unittest` e o cliente de teste do FastAPI. Instale a dependência de testes no ambiente e execute a partir da raiz:

```powershell
poetry run python -m pip install httpx
poetry run python -m unittest discover -s tests -v
```

Esses testes usam um banco SQLite temporário em memória e não acessam nem alteram o PostgreSQL local.
