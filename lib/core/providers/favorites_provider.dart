import 'package:flutter/material.dart';

// Classe de gestão de estado (Provider) para controlar centralizadamente os itens favoritos da aplicação
class FavoritesProvider extends ChangeNotifier {
  // Lista privada que armazena os objetos adicionados como favoritos
  final List<dynamic> _favoritos = [];

  // Getter público que expõe a lista de favoritos para leitura segura a partir da interface
  List<dynamic> get favoritos => _favoritos;

  // Alterna o estado do item: remove-o se já estiver na lista ou adiciona-o caso contrário
  void toggle(dynamic item) {
    if (_favoritos.any((e) => e['id'] == item['id'])) {
      _favoritos.removeWhere((e) => e['id'] == item['id']);
    } else {
      _favoritos.add(item);
    }
    // Notifica todos os widgets ouvintes para reconstruírem com o estado atualizado
    notifyListeners();
  }

  // Remove um item específico da lista de favoritos com base no seu identificador único (ID)
  void remove(dynamic item) {
    _favoritos.removeWhere((e) => e['id'] == item['id']);
    // Notifica todos os widgets ouvintes para reconstruírem com o estado atualizado
    notifyListeners();
  }
}
