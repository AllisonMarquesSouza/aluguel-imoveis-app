import 'screens/perfil_corretor_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/selecao_cidade_screen.dart';
import 'screens/detalhes_imovel_screen.dart';

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
  '/detalhes-imovel': (context) => const DetalhesImovelScreen(),
  '/perfil-corretor': (context) {
    final corretorId =
        ModalRoute.of(context)!.settings.arguments as int;

    return PerfilCorretorScreen(corretorId: corretorId);
  },
  '/perfil-empresa': (context) {
    final empresaId =
        ModalRoute.of(context)!.settings.arguments as int;

    return PerfilEmpresaPorIdScreen(empresaId: empresaId);
  },
},
    );
  }
}