import 'package:flutter/material.dart';

/// Avatar circular con anillo degradado (primario → acento).
/// Muestra foto si existe; si no, iniciales sobre fondo de marca.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 36,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        // Fondo INVERTIDO al tema para contraste: claro en modo oscuro,
        // oscuro en modo claro (onSurface ya es ese color en cada tema).
        backgroundColor: scheme.onSurface,
        foregroundImage:
            (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w700,
            // Legible sobre el fondo invertido, manteniendo la marca.
            color: isDark ? scheme.primary : scheme.tertiary,
          ),
        ),
      ),
    );
  }
}
