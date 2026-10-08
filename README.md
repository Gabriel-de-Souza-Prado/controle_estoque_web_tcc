Markdown
# 📦 Sistema de Controle de Estoque de TI (TCC)

Sistema Web para gerenciamento e controle de estoque de equipamentos de TI, desenvolvido como projeto de TCC. O projeto possui arquitetura em camadas bem definida, autenticação segura via OAuth2 com JWT e integração completa entre back-end e front-end.

---

## 🏗️ Arquitetura e Tecnologias

A aplicação foi desenvolvida seguindo o modelo de separação de responsabilidades em camadas no front-end e no back-end.

### Back-end (FastAPI)
- **Linguagem / Framework:** Python 3.10+ / FastAPI
- **Banco de Dados:** PostgreSQL (via SQLAlchemy ORM)
- **Autenticação:** OAuth2 com senhas criptografadas (`Bcrypt`) e JWT (`Bearer Token`)
- **Segurança:** Middleware CORS configurado para permitir a comunicação com o Flutter Web.

### Front-end (Flutter Web)
A arquitetura do aplicativo em Flutter é organizada rigidamente em camadas para evitar chamadas diretas à API nas telas:
- `models/`: Classes que representam os dados (ex: `UsuarioModel`).
- `repositories/`: Camada responsável pelas chamadas HTTP e integração com o FastAPI.
- `services/`: Camada com a regra de negócio e gerenciamento do estado/token de autenticação.
- `screens/`: Interface com o usuário (`Scaffold`, `Column`, `Row`, `Container`) consumindo apenas os serviços.

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter instalado em sua máquina:
- [Python 3.10+](https://www.python.org/)
- [PostgreSQL](https://www.postgresql.org/) rodando localmente
- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) (com suporte a Web ativado)
- Navegador Google Chrome ou Microsoft Edge

---

## 🚀 Como Executar a API (Back-end)

### 1. Clonar o repositório e acessar a pasta do back-end
```bash
git clone <url-do-seu-repositorio>
cd controle_estoque_web_tcc/backend
2. Criar e ativar o ambiente virtual (Virtualenv)
Windows:

Bash
python -m venv venv
.\venv\Scripts\activate
Linux/Mac:

Bash
python3 -m venv venv
source venv/bin/activate
3. Instalar as dependências
Bash
pip install -r requirements.txt
(Caso necessário, certifique-se de ter as bibliotecas fastapi, uvicorn, sqlalchemy, psycopg, pyjwt, cryptography e passlib[bcrypt] instaladas).

4. Configurar o Banco de Dados
Certifique-se de que o banco PostgreSQL está ativo e ajuste a URL de conexão no arquivo de configuração do SQLAlchemy (ex: postgresql://postgres:senha@localhost:5432/estoque_db).

5. Executar a aplicação FastAPI
Bash
python -m uvicorn app.main:app --reload
A API estará rodando em: http://127.0.0.1:8000

Documentação interativa do Swagger disponível em: http://127.0.0.1:8000/docs

💻 Como Executar o App (Front-end Flutter Web)
1. NAVEGAR até a pasta do front-end
Abre um novo terminal e acesse:

Bash
cd controle_estoque_web_tcc/frontend
2. Baixar as dependências do Flutter
Bash
flutter pub get
3. Executar o aplicativo na Web
Bash
flutter run -d edge
# Ou para rodar no Chrome:
# flutter run -d chrome
O aplicativo abrirá no navegador com as telas de Login e Cadastro, permitindo autenticar o técnico e redirecionar para a Tela Inicial, que consome o endpoint protegido GET /usuarios/eu enviando o token no cabeçalho Authorization: Bearer <token>.

🧪 Executando os Testes Automatizados
O aplicativo contém testes de unidade com uma API mockada (MockClient), garantindo que os componentes de repositório e serviço sejam validados sem necessidade do servidor back-end rodar.

Para executar os testes no Flutter:

Bash
flutter test
📌 Checklist do Projeto Cumprido
[x] Projeto Flutter Web configurado e executando.

[x] Layout com Scaffold, Column, Row e Container.

[x] Tela de Login integrada enviando e-mail/senha e tratando mensagens de erro.

[x] Armazenamento do token de acesso e chamada da rota GET /usuarios/eu.

[x] Tela de Cadastro de novos usuários.

[x] Padrão de arquitetura em camadas (models/, services/, repositories/, screens/).

[x] Middleware CORS habilitado no FastAPI.

[x] Testes unitários com flutter test e Mock de API.

[x] Documentação README com instruções completas.


<ElicitationsGroup message="Com o README pronto, todas as entregas do projeto estão completas! O que gostaria de conferir agora?">
  <Elicitation label="Revisar todo o checklist do professor antes da entrega" query="Faça uma revisão final de todos os pontos exigidos pelo professor para garantir que nada ficou de fora do nosso TCC."/>
</ElicitationsGroup>



As telas têm nome (`lib/routes.dart`) e o `main.dart` liga cada nome à tela. As telas de dentro do app passam pelo `RotaProtegida`: sem sessão, mostram o login.
A sessão (`AuthService`) fica no topo do app, num `ChangeNotifierProvider`, e as telas a leem com `context.read` e `context.watch`: nenhuma recebe a sessão pelo construtor. O token vive só na memória: recarregar a página (F5) sai do app.