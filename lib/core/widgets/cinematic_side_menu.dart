import 'package:flutter/material.dart';

import '../theme/cinematic_theme.dart';
import 'cinematic_glass_card.dart';

class CinematicSideMenu extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String> onItemSelected;

  const CinematicSideMenu({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CinematicGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CinematicColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) {
              final isSelected = item == selectedItem;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onItemSelected(item),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CinematicColors.accent.withOpacity(0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? CinematicColors.accentSoft.withOpacity(0.7)
                            : CinematicColors.stroke,
                      ),
                    ),
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? CinematicColors.textPrimary
                            : CinematicColors.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
