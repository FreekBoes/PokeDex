import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

import 'features/pokemon/presentation/list/pokemon_list_page.dart';
import 'features/pokemon/presentation/detail/pokemon_detail_page.dart';
import 'features/pokemon/presentation/shared/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<int>('favourites');
  await Hive.openBox<int>('team');
  await Hive.openBox<Map>('cache-details');
  await Hive.openBox<List>('cache-list');
  runApp(const ProviderScope(child: PokedexApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ResponsiveRoot(),
      routes: [
        GoRoute(
          path: 'pokemon/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PokemonDetailPage(id: id);
          },
        ),
      ],
    ),
  ],
);

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

/// Split view (tablet/desktop) of alleen lijst (phone)
class ResponsiveRoot extends ConsumerStatefulWidget {
  const ResponsiveRoot({super.key});
  @override
  ConsumerState<ResponsiveRoot> createState() => _ResponsiveRootState();
}

class _ResponsiveRootState extends ConsumerState<ResponsiveRoot> {
  StreamSubscription<String?>? _linkSub;

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    // Web ondersteunt dit niet → gewoon overslaan
    if (kIsWeb) return;

    // Android/iOS:
    // initial link
    getInitialLink().then(_navigateForLink).catchError((_) {});

    // stream (kan op sommige platforms null zijn; try-catch voor zekerheid)
    try {
      _linkSub = linkStream.listen(
        _navigateForLink,
        onError: (_) {},
      );
    } catch (_) {
      // niets doen
    }
  }

  void _navigateForLink(String? link) {
    if (link == null || !mounted) return;
    final uri = Uri.parse(link);
    if (uri.host == 'details' && uri.pathSegments.isNotEmpty) {
      final seg = uri.pathSegments.first;
      final id = int.tryParse(seg);
      if (id != null) context.push('/pokemon/$id');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (!wide) return const PokemonListPage();
        final sel = ref.watch(selectedPokemonIdProvider);
        return Row(
          children: [
            const SizedBox(width: 420, child: PokemonListPage(embedMode: true)),
            const VerticalDivider(width: 1),
            Expanded(
              child: sel == null
                  ? const Center(child: Text('Selecteer een Pokémon'))
                  : PokemonDetailPage(id: sel),
            ),
          ],
        );
      },
    );
  }
}
