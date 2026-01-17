import 'package:flutter/material.dart';

import '../theme/cinematic_theme.dart';
import 'cinematic_glass_card.dart';

class CinematicTopBar extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<String>? onSearchChanged;

  const CinematicTopBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CinematicGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return Row(
            children: [
              const Icon(Icons.play_circle_fill,
                  color: CinematicColors.accentSoft, size: 28),
              const SizedBox(width: 10),
              Text(
                'OmniStream',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CinematicColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedIndex;
                      return InkWell(
                        onTap: () => onItemSelected(index),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CinematicColors.accent.withOpacity(0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? CinematicColors.accentSoft
                                      .withOpacity(0.7)
                                  : CinematicColors.stroke,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: CinematicColors.glow
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            items[index],
                            style: TextStyle(
                              color: isSelected
                                  ? CinematicColors.textPrimary
                                  : CinematicColors.textMuted,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  height: 38,
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: CinematicColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar canales...',
                      hintStyle:
                          TextStyle(color: CinematicColors.textMuted),
                      filled: true,
                      fillColor: CinematicColors.backgroundElevated
                          .withOpacity(0.5),
                      prefixIcon: const Icon(Icons.search,
                          color: CinematicColors.textMuted, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              _TopIconButton(
                icon: Icons.access_time,
                label: 'Horario',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.notifications_none,
                label: 'Alertas',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.search,
                label: 'Buscar',
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CinematicColors.backgroundElevated.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CinematicColors.stroke),
        ),
        child: Icon(icon, color: CinematicColors.textPrimary, size: 20),
      ),
    );
  }
}
