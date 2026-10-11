import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/selecao_cidade_screen.dart';
import 'screens/detalhes_imovel_screen.dart';
import 'screens/favoritos_screen.dart';
import 'screens/perfil_corretor_screen.dart';
import 'models/imovel_detalhe.dart';
import 'services/favoritos_service.dart';
import 'models/imovel.dart';

const String _chaveTemaEscuro = 'tema_escuro';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferencias = SharedPreferencesAsync();
  final temaEscuroInicial =
      await preferencias.getBool(_chaveTemaEscuro) ?? false;
  final favoritosService = FavoritosService(preferencias);
  await favoritosService.carregar();

  runApp(
    AppAluguel(
      preferencias: preferencias,
      temaEscuroInicial: temaEscuroInicial,
      favoritosService: favoritosService,
    ),
  );
}

class AppAluguel extends StatefulWidget {
  final SharedPreferencesAsync preferencias;
  final bool temaEscuroInicial;
  final FavoritosService favoritosService;

  const AppAluguel({
    super.key,
    required this.preferencias,
    required this.temaEscuroInicial,
    required this.favoritosService,
  });

  @override
  State<AppAluguel> createState() => _AppAluguelState();
}

class _AppAluguelState extends State<AppAluguel> {
  late bool _temaEscuro;

  @override
  void initState() {
    super.initState();
    _temaEscuro = widget.temaEscuroInicial;
  }

  Future<void> _salvarTema(bool temaEscuro) async {
    await widget.preferencias.setBool(_chaveTemaEscuro, temaEscuro);

    if (!mounted) return;

    setState(() {
      _temaEscuro = temaEscuro;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Aluguel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _temaEscuro ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
              temaEscuro: _temaEscuro,
              onTemaAlterado: _salvarTema,
              favoritosService: widget.favoritosService,
            ),
        '/selecionar-cidade': (context) => const SelecaoCidadeScreen(),
        '/detalhes-imovel': (context) {
          final imovel =
              ModalRoute.of(context)!.settings.arguments as Imovel;
          return DetalhesImovelScreen(
            imovelResumo: imovel,
            imovelId: imovel.id,
            favoritosService: widget.favoritosService,
          );
        },
        '/favoritos': (context) => FavoritosScreen(
              favoritosService: widget.favoritosService,
            ),
        '/perfil-corretor': (context) {
          final corretor =
              ModalRoute.of(context)!.settings.arguments as CorretorResumo;
          return PerfilCorretorScreen(corretor: corretor);
        },
      },
    );
  }
}
