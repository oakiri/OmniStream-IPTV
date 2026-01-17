import 'package:flutter/material.dart';

import 'package:omnistream_iptv/core/widgets/cinematic_top_bar.dart';

class TopNavigationBar extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<String>? onSearchChanged;

  const TopNavigationBar({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CinematicTopBar(
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      onSearchChanged: onSearchChanged,
    );
  }
}
