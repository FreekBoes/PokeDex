import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers.dart';
import '../../data/pokemon_api.dart';
import '../shared/type_colors.dart';
import '../team_page.dart';
import '../favorites_page.dart';
import '../detail/pokemon_detail_page.dart';
import '../../domain/pokemon_summary.dart';

/// Sorteermodi
enum SortMode { alphaAsc, alphaDesc, numAsc, numDesc }

class PokemonListPage extends ConsumerStatefulWidget {
  const PokemonListPage({super.key, this.embedMode = false});

  final bool embedMode;

  @override
  ConsumerState<PokemonListPage> createState() => _PokemonListPageState();
}

class _PokemonListPageState extends ConsumerState<PokemonListPage> {
  SortMode _sort = SortMode.alphaAsc;
  String? _typeFilter; // null = Alle
  final TextEditingController _searchCtrl = TextEditingController();

  // Volgorde van types die we tonen in de type-sheet
  static const List<String> _types = <String>[
    'all',
    'normal',
    'fire',
    'water',
    'grass',
    'electric',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<SortMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final current = ValueNotifier<SortMode>(_sort);

        Widget option({
          required IconData icon,
          required String title,
          required SortMode value,
        }) {
          return ValueListenableBuilder<SortMode>(
            valueListenable: current,
            builder: (_, cur, __) {
              final isSelected = cur == value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isSelected ? const Color(0xFFE8F7EF) : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => current.value = value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.black87),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2ECC71) : Colors.black26,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sorteren op',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          option(
                            icon: Icons.sort_by_alpha,
                            title: 'Alfabetisch oplopend',
                            value: SortMode.alphaAsc,
                          ),
                          option(
                            icon: Icons.sort_by_alpha,
                            title: 'Alfabetisch aflopend',
                            value: SortMode.alphaDesc,
                          ),
                          option(
                            icon: Icons.tag,
                            title: 'Numeriek oplopend',
                            value: SortMode.numAsc,
                          ),
                          option(
                            icon: Icons.tag,
                            title: 'Numeriek aflopend',
                            value: SortMode.numDesc,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, current.value),
                        child: const Text(
                          'Toepassen',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null && selected != _sort) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _showTypeSheet() async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final current = ValueNotifier<String>(_typeFilter ?? 'all');

        Widget typeTile(String t) {
          final isAll = t == 'all';
          final title = isAll ? 'Alle' : _cap(t);
          return ValueListenableBuilder<String>(
            valueListenable: current,
            builder: (_, cur, __) {
              final isSelected = cur == t;
              final Color base = isAll ? const Color(0xFFE8ECF3) : backgroundForType(t);
              final tileColor = isSelected ? base.withOpacity(0.25) : const Color(0xFFF5F6F8);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => current.value = t,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // kleur-bullet
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isAll ? const Color(0xFFCBD3DF) : base,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2ECC71) : Colors.black26,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filter op type',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          for (final t in _types) typeTile(t),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, current.value),
                        child: const Text(
                          'Toepassen',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedType != null) {
      setState(() => _typeFilter = selectedType == 'all' ? null : selectedType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(pokemonApiProvider);
    final favCount = ref.watch(favouritesProvider).length;
    final teamCount = ref.watch(teamProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        actions: [
          IconButton(
            tooltip: 'Filter op type',
            icon: const Icon(Icons.filter_alt_outlined), // trechter-icoon
            onPressed: _showTypeSheet,
          ),
          IconButton(
            tooltip: 'Sorteren',
            icon: const Icon(Icons.swap_vert), // sort icoon
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: FutureBuilder<List<PokemonSummary>>(
        future: api.fetchList(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('Geen Pokémon gevonden'));
          }

          final list = List<PokemonSummary>.from(snap.data!);

          // Zoeken
          final q = _searchCtrl.text.trim().toLowerCase();
          var filtered = list.where((s) {
            if (q.isEmpty) return true;
            return s.name.toLowerCase().contains(q);
          }).toList();

          // Type-filter (indien gekozen)
          if (_typeFilter != null) {
            final wanted = _typeFilter!;
            filtered = filtered
                .where((s) => s.types.any((t) => t.toLowerCase() == wanted.toLowerCase()))
                .toList();
          }

          // Sorteren
          filtered.sort((a, b) {
            switch (_sort) {
              case SortMode.alphaAsc:
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              case SortMode.alphaDesc:
                return b.name.toLowerCase().compareTo(a.name.toLowerCase());
              case SortMode.numAsc:
                return a.id.compareTo(b.id);
              case SortMode.numDesc:
                return b.id.compareTo(a.id);
            }
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Zoekveld
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Pokémon zoeken',
                  filled: true,
                  fillColor: const Color(0xFFF3F5F8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Info-tegels
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Mijn team',
                      subtitle: '$teamCount pokemons',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D4AFF), Color(0xFF7D6BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TeamPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Favorieten',
                      subtitle: '$favCount pokemons',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1CC7B1), Color(0xFF5DE0C1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FavoritesPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lijst
              for (final s in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SummaryTile(summary: s),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// ---------- Info-tegel ----------
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Item-tegel ----------
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.summary});
  final PokemonSummary summary;

  String _pad3(int n) => n.toString().padLeft(3, '0');

  @override
  Widget build(BuildContext context) {
    final id = summary.id;
    final name =
        summary.name.isEmpty ? 'unknown' : summary.name[0].toUpperCase() + summary.name.substring(1);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PokemonDetailPage(id: id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  summary.imageUrl,
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
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Wrap(
                          spacing: 6,
                          children: summary.types
                              .map((t) => TypePill(t, compact: true, solid: true))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nr. ${_pad3(id)}',
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
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
