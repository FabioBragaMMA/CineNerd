import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/favorites_provider.dart';
import 'pages/splash_page.dart';
import 'pages/home_page.dart';

// Ponto de entrada da aplicação com configuração de geror de estado global para os favoritos
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FavoritesProvider(),
      child: const CineNerdBase(),
    ),
  );
}

// Widget base responsável por gerir as configurações globais da aplicação
class CineNerdBase extends StatefulWidget {
  const CineNerdBase({super.key});

  @override
  State<CineNerdBase> createState() => _CineNerdBaseState();
}

class _CineNerdBaseState extends State<CineNerdBase> {
  // Variáveis de estado para o tema, idioma e controlo de exibição do ecrã splash
  ThemeMode _themeMode = ThemeMode.dark;
  String _idiomaApp = "pt-PT";
  bool _mostraSplash = true;

  // Temporizador para esconder o ecrã splash automaticamente após 3 segundos
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _mostraSplash = false);
    });
  }

  // Alterna o estado do tema entre claro (Light) e escuro (Dark)
  void toggleTheme() => setState(() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  });

  // Atualiza o código do idioma ativo na aplicação
  void mudarIdioma(String novoCodigo) =>
      setState(() => _idiomaApp = novoCodigo);

  // Construção do MaterialApp com definições de tema e alternância dinâmica de ecrãs
  @override
  Widget build(BuildContext context) {
    // Escuta as alterações no provedor de favoritos
    final favs = context.watch<FavoritesProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // Configuração de cores para o tema claro
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.red),
      // Configuração de cores para o tema escuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primarySwatch: Colors.red,
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.yellow,
        ),
      ),
      // Determina se exibe o ecrã inicial de splash ou a página principal da app
      home: _mostraSplash
          ? const CineNerdSplash()
          : CineNerdApp(
              onThemeToggle: toggleTheme,
              themeMode: _themeMode,
              favoritos: favs.favoritos,
              onFavToggle: favs.toggle,
              idioma: _idiomaApp,
              onIdiomaChange: mudarIdioma,
            ),
    );
  }
}
