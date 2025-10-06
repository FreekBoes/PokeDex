import 'package:flutter/material.dart';

/// Kleuren per Pokémon-type (conform gangbare palettes)
const Map<String, Color> kTypeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

Color _onColor(Color bg) => bg.computeLuminance() < 0.5 ? Colors.white : Colors.black87;

/// Compacte, pill-vormige typebadge met nette typografie
class TypePill extends StatelessWidget {
  const TypePill(this.type, {super.key, this.compact = true, this.solid = true});

  final String type;
  final bool compact;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    final base = kTypeColors[t] ?? Theme.of(context).colorScheme.primary;

    final bg = solid ? base : base.withOpacity(0.15);
    final fg = solid ? _onColor(base) : base;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

Color backgroundForType(String type) {
  final base = kTypeColors[type.toLowerCase()];
  return base?.withOpacity(0.85) ?? Colors.grey.shade400;
}
