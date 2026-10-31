import 'package:flutter/material.dart';
import '../widgets/square_progress_loader.dart';

// Widget sem estado (Stateless) que representa o ecrã inicial de carregamento (Splash Screen) da aplicação
class CineNerdSplash extends StatelessWidget {
  const CineNerdSplash({super.key});

  // Constrói a interface gráfica do ecrã de splash com fundo vermelho e elementos centralizados
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Apresenta o logótipo da aplicação a partir dos recursos locais
            Image.asset("assets/CineNerd.png", height: 250),
            // Espaçamento vertical fixo entre o logótipo e o indicador de progresso
            const SizedBox(height: 40),
            // Invoca o loader customizado de quadrados com a cor amarela e tamanho definido
            const SquareProgressLoader(color: Colors.yellow, size: 15),
          ],
        ),
      ),
    );
  }
}
