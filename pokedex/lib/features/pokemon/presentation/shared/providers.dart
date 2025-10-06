import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/pokemon_api.dart';
import '../../domain/pokemon_summary.dart';

// Cross-screen state (gedeeld)
final selectedPokemonIdProvider = StateProvider<int?>((_) => null);

// API client
final pokemonApiProvider = Provider<PokemonApi>((ref) => PokemonApi());

final teamProvider = StateNotifierProvider<TeamNotifier, List<int>>(
  (ref) => TeamNotifier(),
);

// Lijst + zoeken/filters
final pokemonListProvider = FutureProvider<List<PokemonSummary>>((ref) async {
  final api = ref.watch(pokemonApiProvider);
  return api.fetchList();
});
final searchQueryProvider = StateProvider<String>((ref) => '');
final typeFilterProvider = StateProvider<String?>((ref) => null);

// Favorieten
final favouritesBoxProvider = Provider<Box<int>>((_) => Hive.box<int>('favourites'));
final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<int>>((ref) {
  return FavouritesNotifier(ref.watch(favouritesBoxProvider));
});

class FavouritesNotifier extends StateNotifier<Set<int>> {
  FavouritesNotifier(this.box) : super(box.values.toSet());
  final Box<int> box;
  void toggle(int id) {
    final newSet = {...state};
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = newSet;
    box
      ..clear()
      ..addAll(state);
  }
}

// Team (max 6)
final teamBoxProvider = Provider<Box<int>>((_) => Hive.box<int>('team'));


class TeamNotifier extends StateNotifier<List<int>> {
  TeamNotifier() : super(const []);

  void add(int id) {
    if (!state.contains(id)) {
      state = [...state, id];
    }
  }

  void remove(int id) {
    state = state.where((e) => e != id).toList();
  }

  void toggle(int id) {
    state.contains(id) ? remove(id) : add(id);
  }

  bool contains(int id) => state.contains(id);
}


