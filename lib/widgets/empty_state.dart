import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shadow = Theme.of(context).shadowColor;
    final muted = scheme.onSurface.withOpacity(0.65);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _Illustration(icon: icon),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;

  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    final soft = scheme.secondary.withOpacity(0.18);
    return SizedBox(
      height: 110,
      width: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [soft, Colors.transparent],
                radius: 0.9,
              ),
            ),
          ),
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: accent, size: 32),
          ),
          Positioned(
            top: 14,
            left: 20,
            child: _Dot(color: accent.withOpacity(0.7), size: 6),
          ),
          Positioned(
            bottom: 18,
            right: 22,
            child: _Dot(color: accent.withOpacity(0.5), size: 8),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: _Dot(color: accent.withOpacity(0.35), size: 5),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;

  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
