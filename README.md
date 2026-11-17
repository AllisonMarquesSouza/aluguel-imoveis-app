# aluguel_imoveis_app

A new Flutter project.

## Configuração da API

O app usa `API_BASE_URL` para apontar para a API. Sem configuração, usa `http://10.0.2.2:8080` no emulador Android e `http://localhost:8080` nas demais plataformas. Para informar outro endereço, execute o app com `--dart-define=API_BASE_URL=https://seu-servidor`.

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
