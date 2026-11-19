# Publicar o controle de estoque no Render com PostgreSQL no Neon

A interface Flutter será um Static Site no Render. A API FastAPI será um Web Service Docker no Render. O banco PostgreSQL será criado em um projeto próprio do Neon, chamado `progweb3-estoque`.

As configurações abaixo correspondem a este repositório, que tem `Dockerfile`, `pyproject.toml`, `app/` e `alembic/` na raiz e a interface em `frontend/`.

**1. Enviar a versão atualizada ao GitHub**

O Render constrói a versão do código que está no GitHub. Use o repositório [controle_estoque_web_tcc](https://github.com/Gabriel-de-Souza-Prado/controle_estoque_web_tcc).

A cópia preparada nesta máquina fica em:

```text
C:\Users\gabriel.prado\Documents\Codex\2026-11-19\controle_estoque_web_tcc
```

No PowerShell, com o Git disponível, execute:

```powershell
Set-Location 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\controle_estoque_web_tcc'
git status --short
git add Dockerfile .dockerignore .env.example README.md app/main.py app/database.py frontend/lib/repositories/usuario_repository.dart docs/publicacao-render-neon.md
git diff --cached --stat
git commit -m "prepara o estoque para Render e Neon"
git push origin main
```

Conclua a autenticação do GitHub caso ela seja solicitada. Se o Git pedir nome e e-mail, configure seus próprios dados antes de repetir o commit:

```powershell
git config user.name 'SEU_NOME_NO_GITHUB'
git config user.email 'SEU_EMAIL_DO_GITHUB'
```

Se estiver usando o ZIP atualizado, extraia-o. Pelo site do GitHub, abra **Add file → Upload files**, envie o conteúdo da pasta `controle_estoque_web_tcc` para a raiz do repositório e confirme o commit. Inclua os arquivos que começam com ponto e preserve as pastas `app/`, `frontend/` e `docs/`. O ZIP entregue contém o código e o modelo `.env.example`. O `.env` da sua máquina contém configuração privada.

No GitHub, confira se aparecem `Dockerfile` na raiz e `docs/publicacao-render-neon.md`. [Como enviar arquivos pelo GitHub](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository)

**2. Criar o projeto do banco no Neon**

Abra o [console do Neon](https://console.neon.tech/), crie sua conta ou entre e escolha **New Project**. Preencha:

| Campo | Valor |
| --- | --- |
| Nome | `progweb3-estoque` |
| Plano | Free |
| Provedor | AWS |
| Região | US East / N. Virginia (`us-east-1`), se disponível |
| PostgreSQL | Versão padrão oferecida pelo painel |

Escolha o plano gratuito. Guarde o nome da branch e do banco criados pelo painel. O banco pode se chamar `neondb`; esse nome pode ser usado pela aplicação. A API cria as tabelas pelas migrações.

No projeto, clique em **Connect**, selecione a branch e o banco desse projeto e desative **Connection pooling** para obter uma conexão direta. Esta configuração permite usar a mesma URL para a API e para o Alembic que roda na inicialização.

Copie somente a URL de conexão, sem o comando `psql` ou aspas externas. Ela deve ter este formato ilustrativo:

```text
postgresql://USUARIO:SENHA@HOST_DO_NEON/BANCO?sslmode=require&channel_binding=require
```

Troque somente `postgresql://` por `postgresql+psycopg://`:

```text
postgresql+psycopg://USUARIO:SENHA@HOST_DO_NEON/BANCO?sslmode=require&channel_binding=require
```

Mantenha o usuário, a senha, o host, o banco e os parâmetros fornecidos pelo Neon. Cole essa URL no campo privado `DATABASE_URL` da API no Render, na próxima etapa. [Conectar SQLAlchemy ao Neon](https://neon.com/docs/guides/sqlalchemy) · [Conexões diretas e migrações](https://neon.com/docs/connect/connection-pooling)

**3. Criar a API no Render**

Use um workspace dedicado ao Web III. No painel do Render, abra o menu de workspaces no canto superior esquerdo, escolha **+ New Workspace**, informe **Web III — Estoque** e selecione **Hobby**. A franquia de uso pertence ao workspace. Os serviços do estoque serão criados nesse novo espaço. [Workspaces do Render](https://render.com/docs/team-members)

Abra o [painel do Render](https://dashboard.render.com/) e escolha **New → Web Service**. Conecte o repositório do estoque usando **Git Provider**. Se o repositório for público, a opção **Public Git Repository** também permite informar seu endereço.

Use as seguintes configurações:

| Campo | Valor |
| --- | --- |
| Name | `progweb3-estoque-api`, ou um nome disponível |
| Branch | `main` |
| Language / Runtime | Docker |
| Region | Virginia, se a região escolhida no Neon for N. Virginia |
| Root Directory | Em branco |
| Dockerfile Path | `./Dockerfile` |
| Docker Build Context Directory, se aparecer | `.` |
| Instance Type | Free |
| Health Check Path, em Advanced | `/` |

Em **Environment Variables**, configure:

| Nome | Valor |
| --- | --- |
| `DATABASE_URL` | URL direta do Neon com o prefixo `postgresql+psycopg://` e os parâmetros SSL |
| `SECRET_KEY` | Chave criada pelo botão Generate |

O Dockerfile já define o comando de inicialização. Ao iniciar, ele aplica as migrações e executa o Uvicorn na porta indicada por `PORT`.

Clique em **Deploy Web Service** e acompanhe **Logs**. No primeiro deploy, as migrações devem criar `usuarios`, `equipamentos` e `alembic_version`. Quando o serviço ficar ativo, copie o endereço público real.

Abra esse endereço com `/docs` no final. Por exemplo, se o Render atribuir `https://progweb3-estoque-api.onrender.com`, a documentação será `https://progweb3-estoque-api.onrender.com/docs`. O endereço exato depende do nome disponível no Render. [Web Services](https://render.com/docs/web-services) · [Docker no Render](https://render.com/docs/docker) · [Regiões do Render](https://render.com/docs/regions)

**4. Publicar a interface Flutter no Render**

No Render, escolha **New → Static Site**, selecione o mesmo repositório e preencha:

| Campo | Valor |
| --- | --- |
| Name | `progweb3-estoque-app`, ou um nome disponível |
| Branch | `main` |
| Root Directory | `frontend` |
| Publish Directory | `build/web` |

No campo **Build Command**, cole a linha inteira:

```bash
git clone --branch 3.47.6 --depth 1 https://github.com/flutter/flutter.git sdk && sdk/bin/flutter build web --dart-define="API_URL=${API_URL:?Defina API_URL no Render}"
```

Em **Environment Variables**, crie `API_URL` com a origem HTTPS real da sua API, sem barra final. Exemplo ilustrativo:

```text
API_URL=https://progweb3-estoque-api.onrender.com
```

A URL termina no domínio da API. O `/docs` é usado para abrir a documentação no navegador.

Clique em **Deploy Static Site**, acompanhe o build e copie o endereço público real do app quando o site ficar ativo. O build usa Flutter 3.47.6 e Dart 3.13.5, as versões compatíveis com o projeto. [Static Sites no Render](https://render.com/docs/static-sites)

**5. Liberar o endereço do app no CORS da API**

Abra o serviço da API no Render, entre em **Environment → Edit** e adicione:

```text
ENDERECO_DO_APP=https://ENDERECO-REAL-DO-APP.onrender.com
```

Use a origem HTTPS real do Static Site, sem caminho ou barra final. Salve com a opção que faz o deploy da API novamente. Aguarde a API voltar a ficar ativa.

Se o endereço da API mudar, atualize `API_URL` no Static Site e faça um novo build dele. O Flutter incorpora a URL durante a compilação. [Variáveis de ambiente no Render](https://render.com/docs/configure-environment-variables)

**6. Conferir o sistema público**

Abra o endereço do Static Site em uma janela anônima e execute este roteiro:

1. Crie uma conta de técnico.
2. Saia e faça login com essa conta.
3. Abra **Ver os produtos** e cadastre um equipamento com um DTI de teste.
4. Busque uma parte do DTI.
5. Edite o equipamento e confira a atualização da lista.
6. Feche a aba, abra o app novamente e confira a sessão e o equipamento.
7. Abra o projeto do Neon e consulte as tabelas da aplicação para conferir a gravação.
8. Exclua o equipamento de teste pelo app, se desejar.

Os registros criados no SQLite local pertencem ao banco da sua máquina. O novo banco do Neon começa com as tabelas criadas pelas migrações e recebe os cadastros feitos pela aplicação publicada.

Depois de confirmar o funcionamento, substitua o texto pendente da seção **No ar** do README por seus dois endereços reais:

```markdown
### No ar

- App — https://ENDERECO-REAL-DO-APP.onrender.com
- API — https://ENDERECO-REAL-DA-API.onrender.com/docs

O banco PostgreSQL deste projeto é hospedado no Neon.
```

Envie o README atualizado ao GitHub. Os endereços públicos são os links para a entrega e para a apresentação.

**7. Rodar novamente nesta máquina**

Os comandos abaixo usam a cópia e as ferramentas já preparadas nesta máquina. Abra dois terminais PowerShell.

No primeiro, inicie a API:

```powershell
Set-Location 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\controle_estoque_web_tcc'
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

No segundo, sirva o build web já compilado:

```powershell
Set-Location 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\controle_estoque_web_tcc\frontend'
python -m http.server 5000 --bind 127.0.0.1 --directory build/web
```

Abra o [app local](http://127.0.0.1:5000/) e a [documentação da API](http://127.0.0.1:8000/docs). Se uma dessas portas já estiver ocupada pela execução atual, use o servidor que já está aberto ou encerre-o com **Ctrl+C** no terminal correspondente antes de iniciá-lo novamente.

Para desenvolver no Flutter, use a instalação preparada nesta máquina. No segundo terminal, execute este comando no lugar do servidor de arquivos:

```powershell
Set-Location 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\controle_estoque_web_tcc\frontend'
& 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\estoque-ferramentas\sdk\flutter\bin\flutter.bat' pub get
& 'C:\Users\gabriel.prado\Documents\Codex\2026-11-19\estoque-ferramentas\sdk\flutter\bin\flutter.bat' run -d edge --web-port 5000
```

Em um ZIP extraído em outro local, entre na pasta correspondente, prepare o `.env` e as dependências conforme o README e use sua instalação do Flutter para compilar a interface.

**Se aparecer um erro**

| Sintoma | Conferência |
| --- | --- |
| `No module named psycopg2` | O prefixo da URL precisa ser `postgresql+psycopg://`. |
| `password authentication failed` | Copie novamente a conexão do projeto e da branch corretos no Neon. |
| `could not translate host name` ou timeout | Confira o host completo e o estado do compute no Neon. |
| `DATABASE_URL` ou `SECRET_KEY` ausente | Confira as variáveis no Web Service da API. |
| Dockerfile ausente | Na API, Root Directory fica em branco e Dockerfile Path usa `./Dockerfile`. |
| `pubspec.yaml` ausente | No Static Site, Root Directory usa `frontend`. |
| `Defina API_URL no Render` | Defina `API_URL` no Static Site e faça um novo build. |
| Login falha e o console mostra CORS | Confira `ENDERECO_DO_APP` na API e faça seu deploy novamente. |
| Cadastro retorna 422 | Leia a mensagem de validação. DTI e departamento exigem pelo menos três caracteres. |

A API Free do Render pode levar cerca de um minuto para responder após ficar ociosa. As APIs gratuitas do mesmo workspace compartilham a franquia mensal de 750 horas. A execução do estoque também entra nessa soma. O Neon Free tem cotas próprias de armazenamento e computação. [Limites do Render](https://render.com/docs/free) · [Plano do Neon](https://neon.com/pricing)

