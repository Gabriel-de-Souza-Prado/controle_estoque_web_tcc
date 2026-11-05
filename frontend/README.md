# Interface Flutter Web — Controle de Estoque de TI

Configuração da API, banco, checklist da aula 13 e roteiro da demonstração estão no [README principal](../README.md).

## Executar

Com a API iniciada na porta 8000, execute nesta pasta:

```powershell
flutter pub get
flutter run -d edge --web-port 5000
```

## Verificar

```powershell
flutter analyze
flutter test
flutter build web
```

## Camadas

- `screens/`: interface, campos, navegação e estados visuais.
- `services/`: sessão, operações e tradução das falhas para a interface.
- `repositories/`: HTTP, JSON e armazenamento local do token.
- `models/`: dados de usuários e equipamentos.
- `widgets/`: componentes compartilhados, proteção de rotas e avisos.

A busca por DTI e o filtro de status percorrem as camadas até a API. A tela não filtra os equipamentos localmente e não recebe o token para realizar operações do estoque.
