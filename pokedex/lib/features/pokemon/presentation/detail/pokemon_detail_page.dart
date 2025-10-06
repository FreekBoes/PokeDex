import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/type_colors.dart';   // TypePill + backgroundForType(...)
import '../shared/providers.dart';     // favouritesProvider, teamProvider
import '../../data/pokemon_api.dart';  // pokemonApiProvider

// -------- DATA PROVIDER (details) --------
final pokemonDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(pokemonApiProvider);
  return api.fetchDetails(id);
});

class PokemonDetailPage extends ConsumerWidget {
  const PokemonDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetails = ref.watch(pokemonDetailsProvider(id));
    final isFav = ref.watch(favouritesProvider).contains(id);

    return asyncDetails.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Kon details niet laden: $e'))),
      data: (d) {
        // ---------- basis ----------
        final name = (d['name'] as String?) ?? 'unknown';
        final sprites = d['sprites'] as Map<String, dynamic>?;
        final imageUrl =
            sprites?['other']?['official-artwork']?['front_default'] as String? ??
            sprites?['front_default'] as String? ??
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

        final types = ((d['types'] as List<dynamic>? ?? []))
            .map((e) => e['type']['name'] as String)
            .toList();
        final firstType = types.isNotEmpty ? types.first : 'normal';
        final bgColor = backgroundForType(firstType);

        // ---------- stats ----------
        final rawStats = (d['stats'] as List<dynamic>? ?? []);
        final stats = rawStats
            .map((e) => (
                  _prettyStat((e['stat']['name'] as String?) ?? ''),
                  (e['base_stat'] as num?)?.toInt() ?? 0,
                ))
            .toList();
        final total = stats.fold<int>(0, (sum, s) => sum + s.$2);

        // ---------- about ----------
        final height = d['height'] != null ? '${(d['height'] as num) / 10} m' : '-';
        final weight = d['weight'] != null ? '${(d['weight'] as num) / 10} kg' : '-';
        final abilities = ((d['abilities'] as List<dynamic>? ?? []))
            .map((e) => e['ability']['name'] as String)
            .join(', ');

        // ---------- moves ----------
        final levelUpMoves = _extractLevelUpMoves(d);
        final movesToShow = levelUpMoves.take(12).toList();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            foregroundColor: Colors.white, // tekst & iconen wit
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle:
                const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: const BackButton(),
            title: const Text('Terug'),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12), // iets van de rand
                child: IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => ref.read(favouritesProvider.notifier).toggle(id),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // extra ruimte voor sticky button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- afbeelding + lightbox ----------
                Center(
                  child: GestureDetector(
                    onTap: () => _showLightbox(context, imageUrl, id),
                    child: Hero(
                      tag: 'pimg-$id',
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _capitalise(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ===== ABOUT =====
                const _SectionTitle('ABOUT'),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 6, children: types.map((t) => TypePill(t, solid: true)).toList()),
                      const SizedBox(height: 12),
                      _InfoRow('Type', types.map(_capitalise).join(', ')),
                      _InfoRow('Nummer', id.toString().padLeft(3, '0')),
                      _InfoRow('Hoogte', height),
                      _InfoRow('Gewicht', weight),
                      _InfoRow('Abilities', abilities),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ===== STATISTIEKEN =====
                const _SectionTitle('STATISTIEKEN'),
                _SectionCard(
                  child: Column(
                    children: [
                      for (final s in stats) _StatRow(label: s.$1, value: s.$2),
                      const SizedBox(height: 6),
                      _StatRow(label: 'Total', value: total, max: 600),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ===== EVOLUTIE =====
                const _SectionTitle('EVOLUTIE'),
                _EvolutionList(currentId: id),

                const SizedBox(height: 18),

                // ===== MOVESET =====
                const _SectionTitle('MOVESET'),
                _SectionCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movesToShow
                        .map((m) =>
                            _MovePill(_capitalise(m.$1.replaceAll('-', ' ')), level: m.$2))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          // ---------- STICKY CTA ----------
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ref.read(teamProvider.notifier).add(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toegevoegd aan je team')),
                    );
                  },
                  child: const Text('Toevoegen aan mijn team',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- LIGHTBOX ----------
  void _showLightbox(BuildContext context, String imageUrl, int id) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'pimg-$id',
                      child: _ZoomableImage(imageUrl: imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Sluiten',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= helpers / UI =================

List<(String, int)> _extractLevelUpMoves(Map<String, dynamic> details) {
  final rawMoves = details['moves'] as List<dynamic>? ?? const [];
  final Map<String, int> bestLevelByMove = {};

  for (final m in rawMoves) {
    final name = (m['move']?['name'] as String?) ?? '';
    if (name.isEmpty) continue;

    final vgd = m['version_group_details'] as List<dynamic>? ?? const [];
    for (final v in vgd) {
      final method = v['move_learn_method']?['name'] as String?;
      if (method != 'level-up') continue;

      final lvl = (v['level_learned_at'] as num?)?.toInt() ?? 0;
      if (!bestLevelByMove.containsKey(name) || lvl < bestLevelByMove[name]!) {
        bestLevelByMove[name] = lvl;
      }
    }
  }

  final list = bestLevelByMove.entries
      .map<(String, int)>((e) => (e.key, e.value))
      .toList();

  list.sort((a, b) => a.$2.compareTo(b.$2));
  return list;
}

String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// raw stat → label (“Sp. Atk/Sp. Def”)
String _prettyStat(String raw) {
  final k = raw.toLowerCase().replaceAll('_', '-');
  switch (k) {
    case 'hp':
      return 'HP';
    case 'attack':
      return 'Attack';
    case 'defense':
      return 'Defense';
    case 'special-attack':
      return 'Sp. Atk';
    case 'special-defense':
      return 'Sp. Def';
    case 'speed':
      return 'Speed';
    default:
      return k.split('-').map(_capitalise).join(' ');
  }
}

/// Titel BUITEN de kaart
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Witte kaart
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

/// Key–value rij
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

/// Statistiek-rij: LABEL – VALUE – BAR
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.max = 100});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, max);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E6A75),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v / max,
                minHeight: 8,
                backgroundColor: const Color(0xFFF0F2F6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  v > (0.7 * max)
                      ? const Color(0xFF37C569)
                      : v > (0.4 * max)
                          ? const Color(0xFF7DC5A3)
                          : const Color(0xFFE36B66),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Evoluties: verticale lijst ----------
class _EvolutionList extends ConsumerWidget {
  const _EvolutionList({required this.currentId});
  final int currentId;

  int _idFromSpeciesUrl(String url) {
    final parts = url.split('/').where((e) => e.isNotEmpty).toList();
    final last = parts.isNotEmpty ? parts.last : '';
    return int.tryParse(last) ?? 0;
  }

  String _artworkFor(int pokeId) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokeId.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(pokemonApiProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: () async {
        try {
          final species = await api.fetchSpecies(currentId);
          final evoUrl = species['evolution_chain']?['url'] as String?;
          if (evoUrl == null) return null;
          return await api.fetchEvolutionChainByUrl(evoUrl);
        } catch (_) {
          return null;
        }
      }(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SectionCard(child: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) {
          return const _SectionCard(child: Text('Geen evolutie-informatie beschikbaar.'));
        }

        // Chain → vlakke lijst
        final List<_EvoNode> nodes = [];
        void walk(dynamic node) {
          final species = node['species'];
          final name = (species['name'] as String?) ?? '';
          final url = (species['url'] as String?) ?? '';
          final id = _idFromSpeciesUrl(url);
          nodes.add(_EvoNode(id: id, name: name));
          for (final c in (node['evolves_to'] as List? ?? const [])) {
            walk(c);
          }
        }
        walk(snap.data!['chain']);

        // Voor elk id de types ophalen
        return FutureBuilder<List<_EvoNode>>(
          future: () async {
            final detailed = <_EvoNode>[];
            for (final n in nodes) {
              try {
                final det = await api.fetchDetails(n.id);
                final types = ((det['types'] as List?) ?? [])
                    .map((e) => (e['type']['name'] as String?) ?? '')
                    .where((t) => t.isNotEmpty)
                    .toList();
                detailed.add(_EvoNode(id: n.id, name: n.name, types: types));
              } catch (_) {
                detailed.add(n);
              }
            }
            return detailed;
          }(),
          builder: (context, snap2) {
            if (snap2.connectionState != ConnectionState.done) {
              return const _SectionCard(child: Center(child: CircularProgressIndicator()));
            }
            final items = snap2.data ?? nodes;

            return Column(
              children: items.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/pokemon/${n.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _artworkFor(n.id),
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _capitalise(n.name),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: (n.types ?? const [])
                                            .map((t) => TypePill(t, compact: true, solid: true))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nr. ${n.id.toString().padLeft(3, '0')}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _EvoNode {
  _EvoNode({required this.id, required this.name, this.types});
  final int id;
  final String name;
  final List<String>? types;
}

// ---------- Zoom & Pan composable ----------
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.imageUrl});
  final String imageUrl;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _tapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final pos = _tapDetails?.localPosition;
    final current = _controller.value.getMaxScaleOnAxis();
    if (current > 1.0) {
      _controller.value = Matrix4.identity();
    } else if (pos != null) {
      final m = Matrix4.identity()
        ..translate(-pos.dx * 1.5, -pos.dy * 1.5)
        ..scale(2.5);
      _controller.value = m;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _tapDetails = d,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 0.8,
        maxScale: 5,
        clipBehavior: Clip.none,
        child: CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}

// ---------- Move-pill met levelkleur ----------
class _MovePill extends StatelessWidget {
  const _MovePill(this.move, {required this.level});
  final String move;
  final int level;

  Color _levelColor() {
    if (level <= 1) return const Color(0xFF6D4AFF); // paars
    if (level <= 3) return const Color(0xFF1CC7B1); // teal
    return const Color(0xFFF5A623);                 // oranje
  }

  @override
  Widget build(BuildContext context) {
    final badge = _levelColor();
    final bg = Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badge.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badge),
            ),
            child: Text(
              'Level $level',
              style: TextStyle(
                color: badge,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(move, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
