import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/translations.dart';
import '../widgets/square_progress_loader.dart';
import 'favoritos_page.dart';
import 'detalhes_page.dart';

// --- PÁGINA "SOBRE" ---
// Apresenta informações institucionais e do desenvolvedor do projeto.
class SobrePage extends StatelessWidget {
  final String idioma;
  final String Function(String) tFunc;

  const SobrePage({super.key, required this.idioma, required this.tFunc});

  @override
  Widget build(BuildContext context) {
    // Verificação de segurança para o título da página Sobre
    final String titulo = tFunc("about_title").isEmpty
        ? "Sobre o Desenvolvedor"
        : tFunc("about_title");

    return Scaffold(
      appBar: AppBar(title: Text(titulo), backgroundColor: Colors.red),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.red,
              child: Icon(Icons.person, size: 70, color: Colors.yellow),
            ),
            const SizedBox(height: 20),
            _infoRow(Icons.face, "Nome", "Fábio Braga"),
            _infoRow(Icons.calendar_today, "Idade", "20 anos"),
            _infoRow(Icons.email, "Email", "fabioeagle26braga@gmail.com"),
            const Divider(height: 40, color: Colors.red),
            Text(
              "O Projeto",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.red
                    : Colors.yellow,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Este trabalho foi desenvolvido como um projeto individual no âmbito da minha formação no IPCA. "
              "A aplicação foi criada utilizando Flutter e Dart.\n\n"
              "Desenvolvi a CineNerd devido ao meu grande entusiasmo pelo mundo do cinema, filmes, "
              "séries e programas de televisão, procurando unir competências técnicas ao meu gosto pessoal.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Componente auxiliar para renderizar linhas de informação com ícone, rótulo e valor.
  Widget _infoRow(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// --- CLASSE PRINCIPAL ---
// Widget raiz da aplicação que gere os estados globais como tema, favoritos e idioma.
class CineNerdApp extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final List favoritos;
  final Function(dynamic) onFavToggle;
  final String idioma;
  final Function(String) onIdiomaChange;

  const CineNerdApp({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
    required this.favoritos,
    required this.onFavToggle,
    required this.idioma,
    required this.onIdiomaChange,
  });

  @override
  State<CineNerdApp> createState() => _CineNerdAppState();
}

class _CineNerdAppState extends State<CineNerdApp> {
  // Configurações de estado interno, variáveis de paginação e filtros da API TMDB.
  final String _apiKey = "cf8af6ff91e1886dce36dba01daaaedc";
  List _itens = [];
  bool _isLoading = true;
  String _seccaoAtiva =
      "all"; // Controla a exibição: Todos (all), Filmes (movie) ou Séries (tv).
  String _filtroAtivo =
      "popular"; // Critério de ordenação da API (popular, top_rated, recent).
  int? _generoSelecionado;
  int? _plataformaSelecionada;
  int? _anoSelecionado;
  bool _isSortedAlpha = false;
  String _lastQuery = "";
  int _paginaAtual = 1;

  // Sistema de Filtro Familiar e Controlo de Conteúdo Restrito
  bool _mostrarAdulto = false;
  final List<String> _blackList = [
    "hentai",
    "porn",
    "xxx",
    "sex",
    "erotic",
    "nude",
    "adult",
    "pussy",
    "dick",
    "vagina",
    "brazzers",
  ];

  // Método de Localização (Tradução)
  // Retorna a string traduzida com base no idioma atual e chave fornecida.
  String t(String key) {
    try {
      return translations[widget.idioma]?[key] ??
          translations["en"]?[key] ??
          "";
    } catch (e) {
      return "";
    }
  }

  // Mapeamento estático de ID para nome dos provedores de streaming e categorias especiais (Watch Providers / Genres)
  final Map<int, String> _plataformas = {
    8: "Netflix",
    337: "Disney+",
    119: "Amazon Prime",
    350: "Apple TV+",
    1899: "Max",
    1773: "SkyShowtime",
    16: "Desenhos Animados",
  };

  // Geração dinâmica da lista de anos suportados pela aplicação (de 1950 a 2026)
  final List<int> _anos = List<int>.generate(2026 - 1950 + 1, (i) => 2026 - i);

  @override
  void initState() {
    super.initState();
    _fetchData(); // Inicializa a aplicação carregando os dados da API.
  }

  @override
  void didUpdateWidget(CineNerdApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega as informações caso o utilizador mude o idioma nas configurações.
    if (oldWidget.idioma != widget.idioma) {
      _fetchData(query: _lastQuery);
    }
  }

  // --- REQUISIÇÃO DE DADOS (API TMDB) ---
  // Faz o consumo assíncrono dos endpoints de pesquisa ou descoberta com base nos filtros ativos.
  Future<void> _fetchData({String? query, int page = 1}) async {
    if (!mounted) return;
    String currentQuery = (query ?? _lastQuery).toLowerCase().trim();

    // Verificação de segurança contra termos restritos na pesquisa
    if (!_mostrarAdulto &&
        _blackList.any((termo) => currentQuery.contains(termo))) {
      setState(() {
        _itens = [];
        _isLoading = false;
        _lastQuery = "";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Conteúdo restrito pelo Filtro Familiar."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = query ?? _lastQuery;
      _paginaAtual = page;
    });

    List combinedResults = [];
    List<String> typesToFetch = _seccaoAtiva == "all"
        ? ["movie", "tv"]
        : [_seccaoAtiva];

    // Executa as chamadas HTTP adaptando o URL conforme os parâmetros (Pesquisa vs Descoberta)
    for (String type in typesToFetch) {
      String url = "";
      if (_lastQuery.isNotEmpty) {
        // Endpoint de pesquisa por texto livre
        url =
            "https://api.themoviedb.org/3/search/$type?api_key=$_apiKey&query=$_lastQuery&language=${widget.idioma}&page=$_paginaAtual&include_adult=$_mostrarAdulto";
      } else {
        // Endpoint de descoberta avançada com filtros cruzados (género, plataforma, ano)
        String ordenacao = _filtroAtivo == "top_rated"
            ? "vote_average.desc"
            : (_filtroAtivo == "recent"
                  ? (type == "movie"
                        ? "primary_release_date.desc"
                        : "first_air_date.desc")
                  : "popularity.desc");
        url =
            "https://api.themoviedb.org/3/discover/$type?api_key=$_apiKey&language=${widget.idioma}&sort_by=$ordenacao&page=$_paginaAtual&region=PT&include_adult=$_mostrarAdulto";
        if (_generoSelecionado != null)
          url += "&with_genres=$_generoSelecionado";
        if (_plataformaSelecionada != null) {
          String param = type == "tv"
              ? "with_networks"
              : "with_watch_providers";
          url += "&$param=$_plataformaSelecionada&watch_region=PT";
        }
        if (_anoSelecionado != null) {
          url += type == "movie"
              ? "&primary_release_year=$_anoSelecionado"
              : "&first_air_date_year=$_anoSelecionado";
        }
      }

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var results = json.decode(response.body)['results'] as List;
          // Filtragem de segurança local pós-resposta para títulos proibidos
          if (!_mostrarAdulto) {
            results = results.where((item) {
              final title = (item['title'] ?? item['name'] ?? "")
                  .toString()
                  .toLowerCase();
              return !_blackList.any((termo) => title.contains(termo));
            }).toList();
          }
          // Injeta explicitamente o tipo de media para controlo nas páginas de detalhes
          for (var item in results) {
            item['media_type_custom'] = type;
          }
          combinedResults.addAll(results);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    // --- ALGORITMOS DE ORDENAÇÃO LOCAL ---
    // Organiza a lista combinada de resultados (Filmes + Séries) de acordo com o estado do ecrã
    if (_filtroAtivo == "popular")
      combinedResults.sort(
        (a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0),
      );
    else if (_filtroAtivo == "top_rated")
      combinedResults.sort(
        (a, b) => (b['vote_average'] ?? 0).compareTo(a['vote_average'] ?? 0),
      );
    if (_isSortedAlpha)
      combinedResults.sort(
        (a, b) => (a['title'] ?? a['name'] ?? "").toString().compareTo(
          (b['title'] ?? b['name'] ?? "").toString(),
        ),
      );

    if (mounted)
      setState(() {
        _itens = combinedResults;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;

    // --- LÓGICA DA STRING DE FILTROS ---
    // Define dinamicamente o texto com base nos filtros atualmente selecionados para exibição no corpo
    String tituloFiltros = "";

    if (_anoSelecionado != null) {
      tituloFiltros = "${t("years")}: $_anoSelecionado";
    } else if (_generoSelecionado != null) {
      final Map<int, String> generos =
          translations[widget.idioma]?["genres"] as Map<int, String>? ?? {};
      final String nomeGenero = generos[_generoSelecionado] ?? "";
      tituloFiltros = "${t("cats")}: $nomeGenero";
    } else if (_plataformaSelecionada != null) {
      final String nomePlataforma = _plataformas[_plataformaSelecionada] ?? "";
      tituloFiltros = "${t("plats")}: $nomePlataforma";
    } else {
      // Se não houver filtros avançados, mostra a secção base (Todos, Filmes ou Séries)
      tituloFiltros = _seccaoAtiva == "all"
          ? t("all")
          : (_seccaoAtiva == "movie" ? t("movies") : t("series"));
    }

    return Scaffold(
      // --- BARRA SUPERIOR (APPBAR) ---
      // Barra limpa sem títulos textuais. Contém apenas a imagem do logótipo à esquerda e as ações à direita.
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _seccaoAtiva = "all";
                  _generoSelecionado = null;
                  _plataformaSelecionada = null;
                  _anoSelecionado = null;
                  _filtroAtivo = "popular";
                  _isSortedAlpha = false;
                  _lastQuery = "";
                  _paginaAtual = 1;
                });
                _fetchData();
              },
              child: Image.asset("assets/CineNerd.png", height: 70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.yellow,
            ),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(
            icon: Icon(
              Icons.sort_by_alpha,
              color: _isSortedAlpha
                  ? (isLight ? Colors.black : Colors.red)
                  : Colors.yellow,
            ),
            onPressed: () {
              setState(() => _isSortedAlpha = !_isSortedAlpha);
              _fetchData(page: _paginaAtual);
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.yellow),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritosPage(
                  favoritos: widget.favoritos,
                  onRemove: widget.onFavToggle,
                  idioma: widget.idioma,
                  tFunc: t,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.yellow),
            onSelected: (String code) => widget.onIdiomaChange(code),
            itemBuilder: (context) => translations.entries
                .map(
                  (entry) => PopupMenuItem(
                    value: entry.key,
                    child: Text(entry.value["langName"] ?? entry.key),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      // --- MENU LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Center(
                child: Image.asset("assets/CineNerd.png", height: 110),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.red),
              title: Text(t("home")),
              onTap: () {
                setState(() {
                  _seccaoAtiva = "all";
                  _generoSelecionado = null;
                  _plataformaSelecionada = null;
                  _anoSelecionado = null;
                  _lastQuery = "";
                  _paginaAtual = 1;
                });
                _fetchData();
                Navigator.pop(context);
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.calendar_month, color: Colors.red),
              title: Text(t("years")),
              children: _anos
                  .map(
                    (ano) => ListTile(
                      title: Text(ano.toString()),
                      onTap: () {
                        setState(() {
                          _seccaoAtiva = "all";
                          _anoSelecionado = ano;
                          _generoSelecionado = null;
                          _plataformaSelecionada = null;
                          _lastQuery = "";
                          _paginaAtual = 1;
                        });
                        _fetchData();
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
            ExpansionTile(
              leading: const Icon(Icons.category, color: Colors.red),
              title: Text(t("cats")),
              children:
                  (translations[widget.idioma]?["genres"]
                              as Map<int, String>? ??
                          {})
                      .entries
                      .map(
                        (g) => ListTile(
                          title: Text(g.value),
                          onTap: () {
                            setState(() {
                              _seccaoAtiva = "all";
                              _generoSelecionado = g.key;
                              _plataformaSelecionada = null;
                              _anoSelecionado = null;
                              _lastQuery = "";
                              _paginaAtual = 1;
                            });
                            _fetchData();
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
            ),
            ExpansionTile(
              leading: const Icon(Icons.live_tv, color: Colors.red),
              title: Text(t("plats")),
              children: _plataformas.entries
                  .map(
                    (p) => ListTile(
                      leading: const Icon(
                        Icons.play_circle_outline,
                        size: 18,
                        color: Colors.yellow,
                      ),
                      title: Text(p.value),
                      onTap: () {
                        setState(() {
                          _seccaoAtiva = "all";
                          _plataformaSelecionada = p.key;
                          _generoSelecionado = null;
                          _anoSelecionado = null;
                          _lastQuery = "";
                          _paginaAtual = 1;
                        });
                        _fetchData();
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.red),
              title: const Text("Sobre"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SobrePage(idioma: widget.idioma, tFunc: t),
                  ),
                );
              },
            ),
            SwitchListTile(
              secondary: Icon(
                _mostrarAdulto ? Icons.lock_open : Icons.lock,
                color: _mostrarAdulto ? Colors.red : Colors.green,
              ),
              title: const Text("Conteúdo Adulto"),
              subtitle: Text(
                _mostrarAdulto ? "Bloqueio Desativado" : "Conteúdo Protegido",
              ),
              activeColor: Colors.red,
              value: _mostrarAdulto,
              onChanged: (bool value) {
                setState(() {
                  _mostrarAdulto = value;
                  _paginaAtual = 1;
                });
                _fetchData();
              },
            ),
          ],
        ),
      ),
      // --- BARRA DE NAVEGAÇÃO INFERIOR ---
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        currentIndex: _seccaoAtiva == "all"
            ? 0
            : (_seccaoAtiva == "movie" ? 1 : 2),
        onTap: (index) {
          setState(() {
            _seccaoAtiva = index == 0 ? "all" : (index == 1 ? "movie" : "tv");
            _paginaAtual = 1;
          });
          _fetchData();
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: t("all"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.movie),
            label: t("movies"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tv),
            label: t("series"),
          ),
        ],
      ),
      // --- CORPO PRINCIPAL (BODY) ---
      body: Column(
        children: [
          // Campo de Entrada de Texto para Pesquisa Direta
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: t("search"),
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onSubmitted: (val) => _fetchData(query: val, page: 1),
            ),
          ),
          // --- INDICADOR CENTRALIZADO DE FILTROS E METADADOS ATIVOS ---
          // Exibe exclusivamente a informação textual das secções e filtros correntes da aplicação.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            color: Colors.red.withOpacity(0.1),
            width: double.infinity,
            child: Center(
              child: Text(
                tituloFiltros,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.red[900] : Colors.yellow,
                ),
              ),
            ),
          ),
          // Scroll Horizontal de Botões Rápidos (Ordenação por popularidade, avaliação e recentes)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10),
                _botaoRapido(t("popular"), "popular"),
                const SizedBox(width: 10),
                _botaoRapido(t("top"), "top_rated"),
                const SizedBox(width: 10),
                if (_anoSelecionado == null || _anoSelecionado! >= 2025)
                  _botaoRapido(t("recent"), "recent"),
                const SizedBox(width: 10),
              ],
            ),
          ),
          // Grelha Principal adaptável (GridView) para exibição dos cartazes dos itens
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SquareProgressLoader(color: Colors.red, size: 12),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _itens.length,
                    itemBuilder: (context, index) {
                      final item = _itens[index];
                      bool isFav = widget.favoritos.any(
                        (e) => e['id'] == item['id'],
                      );
                      String tipo =
                          item['media_type_custom'] ??
                          (item['title'] != null ? 'movie' : 'tv');
                      double rating = (item['vote_average'] ?? 0).toDouble();

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalhesPage(
                              item: item,
                              favoritos: widget.favoritos,
                              onFavToggle: () => widget.onFavToggle(item),
                              seccao: tipo,
                              idioma: widget.idioma,
                              tFunc: t,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item['poster_path'] != null
                                    ? "https://image.tmdb.org/t/p/w500${item['poster_path']}"
                                    : "https://via.placeholder.com/500x750",
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white70,
                                  size: 20,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  color: Colors.black54,
                                  child: Text(
                                    tipo == 'movie'
                                        ? t("movie_tag")
                                        : t("tv_tag"),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Controlos Inferiores de Paginação (Avançar e Retroceder Páginas)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_paginaAtual > 1)
                  ButtonTheme(
                    child: ElevatedButton(
                      onPressed: () => _fetchData(page: _paginaAtual - 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      child: Text(
                        t("prev"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                _botaoPagina(
                  _paginaAtual.toString(),
                  active: true,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _fetchData(page: _paginaAtual + 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: Text(
                    t("next"),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Componente de botão indicador para a página atual de paginação.
  Widget _botaoPagina(
    String text, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active ? Colors.red : Colors.grey[800],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Componente para renderizar chips de filtragem e ordenação rápida.
  Widget _botaoRapido(String label, String filtro) {
    bool isSelected = _filtroAtivo == filtro;
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.black
              : (isLight ? Colors.black : Colors.white),
        ),
      ),
      backgroundColor: isSelected
          ? Colors.yellow
          : (isLight ? Colors.grey[300] : Colors.grey[800]),
      onPressed: () {
        setState(() {
          _filtroAtivo = filtro;
          _paginaAtual = 1;
        });
        _fetchData();
      },
    );
  }
}
