import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shared/providers.dart';
import '../data/pokemon_api.dart';
import 'shared/type_colors.dart';

class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamIds = ref.watch(teamProvider);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Mijn team'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5C27FE), Color(0xFF8239F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
          child: teamIds.isEmpty
              ? const Center(
                  child: Text('Nog geen Pokémon toegevoegd',
                      style: TextStyle(color: Colors.white)),
                )
              : ListView.separated(
                  itemCount: teamIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final id = teamIds[index];
                    return _SummaryFromApi(id: id);
                  },
                ),
        ),
      ),
    );
  }
}

class _SummaryFromApi extends ConsumerWidget {
  const _SummaryFromApi({required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(pokemonApiProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: api.fetchDetails(id),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 76,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) return const SizedBox.shrink();

        final d = snap.data!;
        final name = _cap((d['name'] as String?) ?? 'unknown');
        final sprites = d['sprites'] as Map<String, dynamic>?;
        final imageUrl =
            sprites?['other']?['official-artwork']?['front_default'] as String? ??
            sprites?['front_default'] as String? ??
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
        final types = ((d['types'] as List<dynamic>? ?? []))
            .map((e) => e['type']?['name'] as String?)
            .whereType<String>()
            .toList();

        return _SummaryTile(id: id, name: name, imageUrl: imageUrl, types: types);
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/pokemon/$id'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, width: 54, height: 54, fit: BoxFit.contain),
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
                          children: types
                              .map((t) => TypePill(t, compact: true, solid: true))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Nr. ${id.toString().padLeft(3, '0')}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
