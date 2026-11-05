# Aula 14 — testes, rubrica e preparação para a nuvem

## Parte 1 — testes do projeto

Na raiz deste projeto fica o backend; não existe uma pasta `backend/`. O frontend fica em `frontend/`.

```powershell
# Na raiz, após poetry install --no-root:
poetry run pytest

# Em outro terminal, dentro de frontend/:
flutter test
```

Nesta máquina, o Poetry está instalado na `.venv`. A partir da raiz também é possível usar `.\.venv\Scripts\poetry.exe run pytest`, sem ativar o ambiente.

### O que é real e o que é substituído

| Teste | Executa de verdade | Substitui |
| --- | --- | --- |
| Endpoint (`tests/test_endpoints.py`) | Cadastro, hash, login, JWT, controllers, services, repositories e SQL | Navegador por TestClient; PostgreSQL por SQLite em memória |
| Formulário (`frontend/test/formulario_test.dart`) | Tela, campos, botão Salvar e validators | Toques pelo WidgetTester; dados inválidos são barrados antes de precisar de API |
| Lista (`frontend/test/lista_test.dart`) | Tela, EquipamentoService, EquipamentoRepository e conversão do JSON | Rede por MockClient; sessão por autenticação simulada |

O `conftest.py` configura variáveis de teste antes de importar a aplicação. Cada teste que usa a fixture `cliente` recebe um banco novo, vazio e em memória. Ao terminar, a conexão é descartada e as dependências são restauradas. O `.env` e o PostgreSQL local não são usados. Os 13 testes anteriores de `unittest` continuam sendo executados pelo pytest.

Cada teste segue **prepara → faz o pedido → confere**. Os novos endpoints cobrem criação com dono do token, ausência de token, estoque compartilhado, edição, exclusão, 404, DTI repetido, busca, senha errada, campo inválido e tokens inválidos/vencidos. Não basta verificar 200: a busca confere os DTIs retornados; a exclusão confere lista e detalhe; a edição lê o valor persistido.

### Evidência: testes vistos passando e falhando

Verificação executada em **05/11/2026**, com alterações temporárias no código real e restauração ao final:

| Regra temporariamente quebrada | Teste que detectou | Resultado com a falha | Depois de restaurar |
| --- | --- | --- | --- |
| Filtro por DTI removido de `EquipamentoRepository.listar` | `test_busca_devolve_so_o_dti_que_combina` | `AssertionError`: retornou `['OUTRO002', 'DTI001']`, quando esperava `['DTI001']` | `1 passed` |
| Validator do DTI devolvendo `null` | `formulário vazio mostra os campos obrigatórios sem chamar API` | `Found 0 widgets with text "Informe DTI"`; `+1 -1: Some tests failed` | `+2: All tests passed!` |

As duas falhas foram desfeitas. Nenhuma alteração temporária faz parte da entrega. Foi usada a busca como regra da API porque o estoque compartilhado é uma adaptação autorizada pelo professor: retirar um isolamento por dono não representaria um defeito neste domínio.

Para repetir a demonstração, altere apenas uma regra por vez, rode o arquivo/teste indicado, observe a falha, restaure a linha e rode novamente. Nunca altere o resultado esperado do teste apenas para fazê-lo passar.

## Parte 2 — rubrica e apresentações

### Cronograma informado pelo professor

| Encontro | Data de 2026 | Atividade |
| --- | --- | --- |
| 14 | 05/11 | Testes, rubrica e conceitos de Docker |
| 15 | 12/11 | Tutorial para publicar o sistema inteiro |
| — | 19/11 | Sem aula: evento |
| 16 | 26/11 | Apresentações |
| 17 | 03/12 | Apresentações |
| 18 | 10/12 | Apresentações |

Cada apresentação tem até 15 minutos, entre 19h15 e 21h30. A escolha do dia e a reserva ainda devem ser feitas pelo aluno no [site de reservas](https://disciplinas.trinove.com.br/apresentacoes/programacao-web-3). Consulte também o [roteiro do professor](https://disciplinas.trinove.com.br/roteiro-apresentacao/programacao-web-3). Nenhum horário foi reservado por esta implementação.

### Situação do projeto por critério

Esta é uma conferência técnica, não uma atribuição de nota. A avaliação final é do professor.

| Critério | Pontos | Situação e evidência |
| --- | --- | --- |
| Autenticação | 0,5 | Implementada: cadastro, senha em hash, login e JWT; testes fazem cadastro/login reais pela API |
| CRUD | 0,5 | Implementado no app e na API, com verificação dos dados após editar/excluir |
| Relacionamento | 0,5 | Adaptação autorizada: estoque compartilhado, com `dono_id` obtido do token; teste verifica acesso por outra conta sem trocar o autor |
| Validação | 0,5 | Validators no formulário; schemas e regras na API; provas de recusas e validação |
| Busca | 0,5 | Campo por DTI; filtro executado pela API no repository |
| Feedback | 0,5 | Avisos de sucesso/erro, carregamento, lista vazia e nova tentativa |
| Camadas | 1,5 | Controllers recebem services; services recebem repositories; sessão/SQL ficam nos repositories. As dependências fazem a composição. Flutter sem HTTP nas telas |
| Testes | 1,0 | Endpoint e widget passando; ambos vistos falhando quando suas regras foram quebradas |
| Nuvem | 1,5 | **Pendente da aula 15:** publicar app/API/PostgreSQL, criar Dockerfile e registrar URLs públicas |
| README | 0,5 | Configuração, execução, testes, seis funcionalidades e roteiro documentados |
| Histórico do Git | 0,5 | **Pendente:** histórico atual tem commits em 3 dias diferentes: 16/10, 27/10 e 05/11. A exigência é 4 dias ou mais; continuar trabalhando e registrando mudanças reais em outro dia |
| Apresentação | 2,0 | **Pendente:** reservar horário, ensaiar e saber explicar qualquer linha; roteiro no README |

### Para explicar o código na apresentação

- `conftest.py`: prepara o banco e o cliente que o pytest entrega ao teste.
- `entrar`: cria uma conta e faz login pelas mesmas rotas do app; não inventa um token nos novos testes.
- `TestClient`: faz pedidos HTTP à aplicação em memória, sem iniciar uvicorn.
- `Depends`: liga as peças da aplicação e permite substituir a conexão por uma de teste.
- `EquipamentoService`: aplica as regras, sem receber uma sessão ou fazer SQL.
- `EquipamentoRepository`: consulta e grava; é a camada que conhece a sessão.
- `WidgetTester`: abre a tela, digita, toca e procura o resultado visual.
- `MockClient`: substitui a rede por respostas escolhidas no teste.

## Parte 3 — conceitos de publicação e Docker

O material desta parte é de leitura: a prática de publicação está prevista para o encontro 15. Não foi criado um serviço de nuvem nem instalado Docker nesta etapa.

| Conceito | Aplicação no controle de estoque |
| --- | --- |
| Dockerfile | Receita para empacotar a API; precisa usar Python compatível com `requires-python >=3.14`, adaptando o exemplo do professor que usa 3.12 |
| Imagem | API e dependências empacotadas; não inclui `.env`, credenciais ou banco local |
| Contêiner | Imagem em execução; dados permanentes ficam no PostgreSQL externo |
| Variáveis de ambiente | `DATABASE_URL` e `SECRET_KEY` serão configuradas no serviço; localmente vêm do `.env` |
| Migrações | A inicialização deverá aplicar `alembic upgrade head` antes de iniciar uvicorn |
| Porta | A API deverá escutar em `0.0.0.0` e na porta indicada pelo serviço |
| Frontend | A compilação publicada deverá usar o endereço público da API, em vez de `localhost` |
| Docker Compose | Serve para orquestrar várias peças numa máquina; não é exigido no caminho de serviços separados proposto na aula |

Na aula 15, será necessário preparar o Dockerfile e `.dockerignore`, configurar endereço da API no Flutter e CORS, publicar as três peças e repetir o fluxo de cadastro/login/CRUD pelos endereços públicos. O banco da apresentação precisa continuar disponível na data escolhida. Confirme os limites do provedor quando for criar os serviços.
