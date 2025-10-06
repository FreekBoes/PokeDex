class PokemonSummary {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  const PokemonSummary({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  static String _firstNonEmptyStr(Iterable<dynamic> candidates, [String fallback = '']) {
    for (final c in candidates) {
      final s = c?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  static int _readId(Map<String, dynamic> json) {
    final idCandidates = [json['id'], json['number'], json['nr'], json['dexNr'], json['dex']];
    for (final c in idCandidates) {
      if (c is int) return c;
      if (c is String) {
        final n = int.tryParse(c);
        if (n != null) return n;
      }
    }
    return 0;
  }

  /// Haal een nette lijst van type-namen uit verschillende vormen:
  /// - ["grass","poison"]
  /// - [{"slot":1,"type":{"name":"grass"}}, {"slot":2,"type":{"name":"poison"}}]
  /// - [{"name":"grass"}, {"name":"poison"}]
  static List<String> _readTypes(dynamic raw) {
    final out = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          out.add(item);
        } else if (item is Map) {
          // vorm: {"type":{"name":"grass"}} of {"name":"grass"}
          final t = item['type'];
          if (t is Map && t['name'] != null) {
            out.add(t['name'].toString());
          } else if (item['name'] != null) {
            out.add(item['name'].toString());
          } else {
            // laatste redmiddel: hele map -> string en probeer 'name' te pakken met regex (desnoods)
            final s = item.toString();
            final match = RegExp(r'name:\s*([a-zA-Z]+)').firstMatch(s);
            if (match != null) out.add(match.group(1)!.toLowerCase());
          }
        }
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      out.addAll(raw.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty));
    }
    return out;
  }

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    final id = _readId(json);

    final name = _firstNonEmptyStr([
      json['name'],
      json['displayName'],
      json['pokemon'],
    ], 'unknown');

    final img = _firstNonEmptyStr([
      json['image'],
      json['imageUrl'],
      json['image_url'],
      json['sprite'],
      json['thumbnail'],
      json['img'],
    ]);

    final rawTypes = json['types'] ?? json['type'] ?? json['typing'];
    final types = _readTypes(rawTypes);

    final fallbackArt = (id > 0)
        ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png'
        : '';

    return PokemonSummary(
      id: id,
      name: name,
      imageUrl: img.isNotEmpty ? img : fallbackArt,
      types: types,
    );
  }
}
