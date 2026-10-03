import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/selecao_cidade_screen.dart';
import 'screens/detalhes_imovel_screen.dart';
import 'screens/perfil_corretor_screen.dart';
import 'models/imovel_detalhe.dart';

void main() {
  runApp(const AppAluguel());
}

class AppAluguel extends StatelessWidget {
  const AppAluguel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Aluguel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      // Definindo as rotas pré-montadas do projeto
           initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/selecionar-cidade': (context) => const SelecaoCidadeScreen(),
        '/detalhes-imovel': (context) {
          final imovelId =
              ModalRoute.of(context)!.settings.arguments as String;

          return DetalhesImovelScreen(imovelId: imovelId);
        },
        '/perfil-corretor': (context) {
          final corretor =
              ModalRoute.of(context)!.settings.arguments as CorretorResumo;
          return PerfilCorretorScreen(corretor: corretor);
        },
      },
    );
  }
}
