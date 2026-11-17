# aluguel_imoveis_app

A new Flutter project.

## Configuração da API

O app usa `API_BASE_URL` para apontar para a API. Sem configuração, usa `http://10.0.2.2:8080` no emulador Android e `http://localhost:8080` nas demais plataformas. Para informar outro endereço, execute o app com `--dart-define=API_BASE_URL=https://seu-servidor`.

O app autentica corretores por `POST /auth/login` e envia o JWT nas chamadas protegidas. O token fica somente em memória e é descartado ao encerrar o app. Com uma conta de corretor ativa, o app consulta `/cidade`, `/imovel` e `/imovel/{id}`; a API limita os imóveis à empresa do corretor e não oferece filtro por cidade nem paginação, então esses filtros são aplicados localmente sobre a lista retornada. A listagem pública de imóveis ainda não está disponível na API. Perfis públicos de corretores e imagens usam as rotas públicas correspondentes.

Durante a execução em modo debug, a tela de acesso mostra atalhos para preencher as credenciais de demonstração de corretor e administrador. Para exibi-los em uma compilação de teste, use `--dart-define=APP_TEST_MODE=true`. Essas contas só funcionam quando a API é iniciada com o perfil `demo`; a conta de administrador não tem permissão para consultar cidades e imóveis.

As chamadas do app usam os caminhos documentados pela API (`/cidade`, `/imovel` e `/imovel/{id}`). No estado atual, as consultas de cidades e imóveis exigem autenticação, e imóveis não podem ser filtrados por cidade no servidor. O app mostra o erro recebido nesses casos e não substitui os dados por exemplos locais. A vitrine pública depende de endpoints públicos correspondentes na API.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
