import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  static const String _apiKey = "AQUI_A_TUA_API_KEY";
  static const String _base = "https://api.themoviedb.org/3";

  // ---------------------------------------------
  // FUNÇÃO PRINCIPAL
  // ---------------------------------------------
  Future<List<Map<String, dynamic>>> listar({
    required String secao, // all / movie / tv
    required String filtro, // popular / top_rated / recent
    required int pagina,
    String? query,
    int? ano,
    int? genero,
    String? plataforma,
    bool incluirAdultos = false,
  }) async {
    // PESQUISA
    if (query != null && query.isNotEmpty) {
      return _buscarPesquisa(query, pagina, incluirAdultos);
    }

    // FILMES
    if (secao == "movie") {
      return _buscarFilmes(
        filtro: filtro,
        pagina: pagina,
        ano: ano,
        genero: genero,
        incluirAdultos: incluirAdultos,
      );
    }

    // SÉRIES
    if (secao == "tv") {
      return _buscarSeries(
        filtro: filtro,
        pagina: pagina,
        ano: ano,
        genero: genero,
      );
    }

    // TUDO
    return _buscarTudo(
      filtro: filtro,
      pagina: pagina,
      ano: ano,
      genero: genero,
      incluirAdultos: incluirAdultos,
    );
  }

  // ---------------------------------------------
  // BUSCAR FILMES
  // ---------------------------------------------
  Future<List<Map<String, dynamic>>> _buscarFilmes({
    required String filtro,
    required int pagina,
    int? ano,
    int? genero,
    bool incluirAdultos = false,
  }) async {
    final endpoint = "/movie/$filtro";

    final params = {
      "api_key": _apiKey,
      "language": "pt-PT",
      "page": pagina.toString(),
      "include_adult": incluirAdultos.toString(),
    };

    if (ano != null) params["primary_release_year"] = ano.toString();
    if (genero != null) params["with_genres"] = genero.toString();

    final data = await _request(endpoint, params);

    return (data["results"] as List)
        .map(
          (e) =>
              Map<String, dynamic>.from(e)
                ..addAll({"media_type_custom": "movie"}),
        )
        .toList();
  }

  // ---------------------------------------------
  // BUSCAR SÉRIES
  // ---------------------------------------------
  Future<List<Map<String, dynamic>>> _buscarSeries({
    required String filtro,
    required int pagina,
    int? ano,
    int? genero,
  }) async {
    final endpoint = "/tv/$filtro";

    final params = {
      "api_key": _apiKey,
      "language": "pt-PT",
      "page": pagina.toString(),
    };

    if (ano != null) params["first_air_date_year"] = ano.toString();
    if (genero != null) params["with_genres"] = genero.toString();

    final data = await _request(endpoint, params);

    return (data["results"] as List)
        .map(
          (e) =>
              Map<String, dynamic>.from(e)..addAll({"media_type_custom": "tv"}),
        )
        .toList();
  }

  // ---------------------------------------------
  // BUSCAR TUDO (movie + tv)
  // ---------------------------------------------
  Future<List<Map<String, dynamic>>> _buscarTudo({
    required String filtro,
    required int pagina,
    int? ano,
    int? genero,
    bool incluirAdultos = false,
  }) async {
    final filmes = await _buscarFilmes(
      filtro: filtro,
      pagina: pagina,
      ano: ano,
      genero: genero,
      incluirAdultos: incluirAdultos,
    );

    final series = await _buscarSeries(
      filtro: filtro,
      pagina: pagina,
      ano: ano,
      genero: genero,
    );

    final tudo = [...filmes, ...series];

    tudo.sort((a, b) {
      final pa = (a["popularity"] ?? 0).toDouble();
      final pb = (b["popularity"] ?? 0).toDouble();
      return pb.compareTo(pa);
    });

    return tudo;
  }

  // ---------------------------------------------
  // PESQUISA
  // ---------------------------------------------
  Future<List<Map<String, dynamic>>> _buscarPesquisa(
    String query,
    int pagina,
    bool incluirAdultos,
  ) async {
    final params = {
      "api_key": _apiKey,
      "language": "pt-PT",
      "query": query,
      "page": pagina.toString(),
      "include_adult": incluirAdultos.toString(),
    };

    final data = await _request("/search/multi", params);

    return (data["results"] as List)
        .where((e) => e["media_type"] == "movie" || e["media_type"] == "tv")
        .map(
          (e) =>
              Map<String, dynamic>.from(e)
                ..addAll({"media_type_custom": e["media_type"]}),
        )
        .toList();
  }

  // ---------------------------------------------
  // REQUEST GENÉRICO
  // ---------------------------------------------
  Future<Map<String, dynamic>> _request(
    String endpoint,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse("$_base$endpoint").replace(queryParameters: params);

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("Erro TMDB: ${res.statusCode}");
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }
}
