import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../pokemon/domain/pokemon_summary.dart';

class PokemonApi {
  PokemonApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  final Dio _dio;

  static const String listBase =
      'https://stoplight.io/mocks/appwise-be/pokemon/57519009';
  static const String pokeApiBase = 'https://pokeapi.co/api/v2';

  Future<List<PokemonSummary>> fetchList({bool useCache = true}) async {
    final cache = Hive.box<List>('cache-list');
    if (useCache) {
      final cached = cache.get('list');
      if (cached != null && cached.isNotEmpty) {
        return cached
            .cast<Map>()
            .map((e) => PokemonSummary.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    final res = await _dio.get('$listBase/pokemon');
    final data = (res.data as List).cast<Map<String, dynamic>>();
    cache.put('list', data);
    return data.map(PokemonSummary.fromJson).toList();
  }

  Future<Map<String, dynamic>> fetchDetails(int id,
      {bool useCache = true}) async {
    final cache = Hive.box<Map>('cache-details');
    if (useCache && cache.containsKey(id)) {
      return Map<String, dynamic>.from(
          cache.get(id) as Map<dynamic, dynamic>);
    }
    final res = await _dio.get('$pokeApiBase/pokemon/$id');
    final map = Map<String, dynamic>.from(res.data as Map);
    cache.put(id, map);
    return map;
  }

  Future<Map<String, dynamic>> fetchSpecies(int id) async {
    final res = await _dio.get('$pokeApiBase/pokemon-species/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> fetchEvolutionChainByUrl(String url) async {
    final res = await _dio.get(url);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
