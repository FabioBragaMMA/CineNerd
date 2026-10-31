import 'package:flutter/material.dart';

// Widget customizado que cria uma barra de carregamento composta por pequenos quadrados animados
class SquareProgressLoader extends StatefulWidget {
  final Color color;
  final double size;
  const SquareProgressLoader({super.key, required this.color, this.size = 12});

  @override
  State<SquareProgressLoader> createState() => _SquareProgressLoaderState();
}

// Estado do widget utilizando SingleTickerProviderStateMixin para permitir animações controladas pelo tempo
class _SquareProgressLoaderState extends State<SquareProgressLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Inicializa o controlador da animação configurado para se repetir infinitamente
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  // Liberta os recursos ocupados pelo controlador de animação quando o widget é destruído
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Constrói uma linha horizontal com 10 quadrados que alteram a opacidade de forma desfasada
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(10, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Cálculos matemáticos para criar o efeito de atraso (delay) sequencial em cada quadrado
            double delay = index / 10;
            double progress = (_controller.value - delay).clamp(0.0, 1.0);
            double opacity = (1.0 - (progress * 2)).clamp(0.2, 1.0);
            if (progress > 0.5) opacity = 0.2;

            // Renderização visual de cada quadrado com a opacidade calculada dinamicamente
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(opacity),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
