import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    required this.onWallTap,
    required this.onCasesTap,
    super.key,
  });

  final VoidCallback onWallTap;
  final VoidCallback onCasesTap;

  @override
  Widget build(BuildContext context) => BottomAppBar(
    height: 68,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      children: [
        Expanded(
          child: _BottomItem(
            icon: Icons.view_agenda_outlined,
            label: 'Muro',
            selected: true,
            onTap: onWallTap,
          ),
        ),
        const Expanded(child: SizedBox()),
        Expanded(
          child: _BottomItem(
            icon: Icons.forum_outlined,
            label: 'Casos',
            onTap: onCasesTap,
          ),
        ),
      ],
    ),
  );
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: YuntaColors.primary),
          Text(label, style: const TextStyle(color: YuntaColors.primary)),
        ],
      ),
    ),
  );
}
