# aluguel_imoveis_app

A new Flutter project.

## Configuração da API

O app usa `API_BASE_URL` para apontar para a API. Sem configuração, usa `http://10.0.2.2:8080` no emulador Android e `http://localhost:8080` nas demais plataformas. Para informar outro endereço, execute o app com `--dart-define=API_BASE_URL=https://seu-servidor`.

O app abre na vitrine sem exigir login. O corretor entra por `POST /auth/login`; o JWT é guardado localmente e enviado nas chamadas protegidas, e sair remove o token do aparelho. A área do corretor consulta `GET /imovel`, que limita os resultados à empresa do usuário autenticado. Busca e filtro por situação ficam na tela do acervo. A resposta atual de `GET /imovel` não inclui situação do imóvel, então registros são apresentados como “Situação não informada” até a API expor esse campo. A listagem pública de imóveis ainda não está disponível na API. Perfis públicos de corretores e imagens usam as rotas públicas correspondentes.

Durante a execução em modo debug, a tela de acesso mostra atalhos para preencher as credenciais de demonstração de corretor e administrador. Para exibi-los em uma compilação de teste, use `--dart-define=APP_TEST_MODE=true`. Essas contas só funcionam quando a API é iniciada com o perfil `demo`; a conta de administrador não tem permissão para consultar cidades e imóveis.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
