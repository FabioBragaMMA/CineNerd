import 'package:flutter/material.dart';
import 'detalhes_page.dart';

// Página que apresenta a lista de itens guardados como favoritos pelo utilizador
class FavoritosPage extends StatefulWidget {
  final List favoritos;
  final Function(dynamic) onRemove;
  final String idioma;
  final Function(String) tFunc;

  const FavoritosPage({
    super.key,
    required this.favoritos,
    required this.onRemove,
    required this.idioma,
    required this.tFunc,
  });

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  // Guarda o texto introduzido no campo de pesquisa para filtrar os favoritos
  String _filtro = "";

  @override
  Widget build(BuildContext context) {
    // Filtragem da lista com base no título ou nome
    final favoritosFiltrados = widget.favoritos.where((item) {
      final nome = (item['title'] ?? item['name'] ?? "")
          .toString()
          .toLowerCase();
      return nome.contains(_filtro.toLowerCase());
    }).toList();

    return Scaffold(
      // Barra superior da página contendo o título e o campo de pesquisa integrado
      appBar: AppBar(
        title: Text(widget.tFunc("fav")),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: TextField(
              // Atualiza o estado do filtro e recarrega a lista a cada letra digitada
              onChanged: (value) {
                setState(() {
                  _filtro = value;
                });
              },
              decoration: InputDecoration(
                hintText: widget.tFunc(
                  "search",
                ), // Utiliza a tradução já existente
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      // Corpo da página com validação de estados: lista vazia, sem resultados ou exibição dos dados
      body: widget.favoritos.isEmpty
          // Estado 1: Caso não existam itens adicionados aos favoritos
          ? const Center(
              child: Icon(Icons.heart_broken, size: 100, color: Colors.grey),
            )
          : favoritosFiltrados.isEmpty
          // Estado 2: Caso a pesquisa não corresponda a nenhum item da lista
          ? const Center(child: Text("Nenhum favorito encontrado"))
          // Estado 3: Renderização da lista com os favoritos encontrados
          : ListView.builder(
              itemCount: favoritosFiltrados.length,
              itemBuilder: (context, index) {
                final item = favoritosFiltrados[index];

                // Identifica se o item é um filme ou uma série de TV para enviar à página de detalhes
                String tipo =
                    item['media_type_custom'] ??
                    (item['title'] != null ? 'movie' : 'tv');

                return ListTile(
                  // Navegação para a página de detalhes do item selecionado
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalhesPage(
                        item: item,
                        favoritos: widget.favoritos,
                        onFavToggle: () => widget.onRemove(item),
                        seccao: tipo,
                        idioma: widget.idioma,
                        tFunc: widget.tFunc,
                      ),
                    ),
                  ),
                  // Exibição da imagem de capa do item ou de um placeholder caso não exista
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item['poster_path'] != null
                          ? "https://image.tmdb.org/t/p/w200${item['poster_path']}"
                          : "https://via.placeholder.com/200x300",
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(item['title'] ?? item['name'] ?? ""),
                  // Botão lateral para remover o item diretamente da lista de favoritos
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onRemove(item),
                  ),
                );
              },
            ),
    );
  }
}
