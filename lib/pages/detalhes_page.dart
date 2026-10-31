import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Página de detalhes que exibe informações completas sobre um filme ou série de TV selecionada
class DetalhesPage extends StatefulWidget {
  final dynamic item;
  final List favoritos;
  final VoidCallback onFavToggle;
  final String seccao;
  final String idioma;
  final Function(String) tFunc;

  const DetalhesPage({
    super.key,
    required this.item,
    required this.favoritos,
    required this.onFavToggle,
    required this.seccao,
    required this.idioma,
    required this.tFunc,
  });

  @override
  State<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
  // Chave de autenticação para consumo da API do The Movie Database (TMDB)
  final String _apiKey = "cf8af6ff91e1886dce36dba01daaaedc";

  // Listas estruturadas para armazenar os dados complementares obtidos da API
  List<dynamic> _atores = [];
  List<dynamic> _equipa = [];
  List<dynamic> _produtoras = [];
  List<dynamic> _streaming = [];

  // Controla o estado de carregamento das requisições assíncronas assinaladas à página
  bool _loadingExtra = true;

  // Variáveis para guardar os textos traduzidos correspondentes ao idioma selecionado
  String _tituloTraduzido = "";
  String _overviewTraduzida = "";

  @override
  void initState() {
    super.initState();
    // Inicia a execução das chamadas à API assim que o estado do widget é criado
    _fetchExtraDetails();
  }

  // Realiza os pedidos HTTP paralelos para recolher os detalhes, créditos e plataformas de streaming do item
  Future<void> _fetchExtraDetails() async {
    final String type = widget.seccao;
    final int id = widget.item['id'];

    try {
      // Requisita os dados principais e as traduções disponíveis do conteúdo
      final mainRes = await http.get(
        Uri.parse(
          "https://api.themoviedb.org/3/$type/$id?api_key=$_apiKey&language=${widget.idioma}&append_to_response=translations",
        ),
      );

      // Requisita a equipa técnica e o elenco (créditos) do conteúdo
      final creditRes = await http.get(
        Uri.parse(
          "https://api.themoviedb.org/3/$type/$id/credits?api_key=$_apiKey&language=${widget.idioma}",
        ),
      );

      // Requisita os fornecedores e plataformas de streaming disponíveis
      final watchRes = await http.get(
        Uri.parse(
          "https://api.themoviedb.org/3/$type/$id/watch/providers?api_key=$_apiKey",
        ),
      );

      if (!mounted) return;

      setState(() {
        // Processamento da resposta principal e extração das traduções de idioma
        if (mainRes.statusCode == 200) {
          var data = json.decode(mainRes.body);

          _produtoras = data['production_companies'] ?? [];

          String? tempTitle = data['title'] ?? data['name'];
          String? tempOverview = data['overview'];

          if (data['translations'] != null) {
            var translations = data['translations']['translations'] as List;
            var langCode = widget.idioma.split('-')[0];

            var targetTranslation = translations.firstWhere(
              (t) => t['iso_639_1'] == langCode,
              orElse: () => null,
            );

            if (targetTranslation != null &&
                targetTranslation['data'] != null) {
              var d = targetTranslation['data'];

              if (d['title'] != null && d['title'].toString().isNotEmpty)
                tempTitle = d['title'];

              if (d['name'] != null && d['name'].toString().isNotEmpty)
                tempTitle = d['name'];

              if (d['overview'] != null && d['overview'].toString().isNotEmpty)
                tempOverview = d['overview'];
            }
          }

          _tituloTraduzido = tempTitle ?? "";
          _overviewTraduzida = tempOverview ?? "";
        }

        // Processamento e armazenamento do elenco e da equipa técnica
        if (creditRes.statusCode == 200) {
          var data = json.decode(creditRes.body);
          _atores = data['cast'] ?? [];
          _equipa = data['crew'] ?? [];
        }

        // Processamento e filtragem das plataformas de streaming disponíveis em Portugal (PT)
        if (watchRes.statusCode == 200) {
          var results = json.decode(watchRes.body)['results'];
          if (results != null && results['PT'] != null) {
            _streaming = results['PT']['flatrate'] ?? [];
          }
        }

        _loadingExtra = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingExtra = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se o item atual já se encontra guardado na lista de favoritos
    bool isFav = widget.favoritos.any((e) => e['id'] == widget.item['id']);

    // Define o título a exibir priorizando a tradução obtida da API
    String titulo = _tituloTraduzido.isNotEmpty
        ? _tituloTraduzido
        : (widget.item['title'] ?? widget.item['name'] ?? "Info");

    double rating = (widget.item['vote_average'] ?? 0).toDouble();

    // Filtra a equipa técnica para isolar apenas os cargos de Direção e Produção
    List prodFiltro = _equipa
        .where(
          (e) =>
              e['job'] == 'Director' ||
              e['job'] == 'Producer' ||
              e['job'] == 'Executive Producer',
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          // Botão de alternância para adicionar ou remover o item dos favoritos
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.yellow,
            ),
            onPressed: () => widget.onFavToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bloco de exibição do poster oficial do conteúdo com fallback para placeholder
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Image.network(
                widget.item['poster_path'] != null
                    ? "https://image.tmdb.org/t/p/w500${widget.item['poster_path']}"
                    : "https://via.placeholder.com/500x750",
                fit: BoxFit.contain,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Secção do título e da respetiva nota de avaliação (Rating)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Secção com o resumo informativo (sinopse/overview) do conteúdo
                  Text(
                    _overviewTraduzida.isNotEmpty
                        ? _overviewTraduzida
                        : (widget.item['overview'] ?? ""),
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // Botão exterior que redireciona o utilizador para a pesquisa do trailer no YouTube
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse(
                          "https://www.youtube.com/results?search_query=$titulo+trailer",
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(widget.tFunc("trailer")),
                    ),
                  ),

                  const Divider(height: 40, color: Colors.grey),

                  // Secção das plataformas de streaming onde o conteúdo está disponível para visualização
                  _buildSectionTitle(widget.tFunc("streaming")),
                  if (_loadingExtra)
                    const Center(child: CircularProgressIndicator())
                  else if (_streaming.isEmpty)
                    Text(widget.tFunc("no_info"))
                  else
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _streaming.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "https://image.tmdb.org/t/p/w200${_streaming[i]['logo_path']}",
                              width: 50,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Secção de exibição em carrossel horizontal do elenco principal de atores (limite de 10)
                  _buildSectionTitle(widget.tFunc("cast")),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _atores.length > 10 ? 10 : _atores.length,
                      itemBuilder: (context, i) => _buildAvatarItem(
                        _atores[i]['name'],
                        _atores[i]['profile_path'],
                        subText: _atores[i]['character'],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Secção de exibição em carrossel horizontal dos membros da equipa de produção (limite de 5)
                  _buildSectionTitle(widget.tFunc("production")),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: prodFiltro.length > 5 ? 5 : prodFiltro.length,
                      itemBuilder: (context, i) => _buildAvatarItem(
                        prodFiltro[i]['name'],
                        prodFiltro[i]['profile_path'],
                        subText: prodFiltro[i]['job'],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Secção final em bloco com os logótipos e marcas das produtoras/estúdios envolvidos
                  _buildSectionTitle(widget.tFunc("studios")),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    children: _produtoras
                        .map(
                          (p) => Column(
                            children: [
                              if (p['logo_path'] != null)
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Image.network(
                                    "https://image.tmdb.org/t/p/w200${p['logo_path']}",
                                    height: 30,
                                  ),
                                )
                              else
                                const Icon(Icons.business, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                p['name'],
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construtor auxiliar de títulos estilizados para padronização das secções da página
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  // Construtor auxiliar reutilizável para renderizar avatares circulares de pessoas com foto e descrição
  Widget _buildAvatarItem(String name, String? path, {String? subText}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[900],
            backgroundImage: path != null
                ? NetworkImage("https://image.tmdb.org/t/p/w200$path")
                : null,
            child: path == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          if (subText != null)
            Text(
              subText,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
