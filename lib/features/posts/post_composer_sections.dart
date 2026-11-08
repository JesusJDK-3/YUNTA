import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';

Widget composerSection(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget child,
}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: YuntaColors.surfaceWhite,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .65)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: YuntaColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      const SizedBox(height: 14),
      child,
    ],
  ),
);

Widget composerModeOption(
  BuildContext context, {
  required String value,
  required String title,
  required String subtitle,
  required IconData icon,
  required bool selected,
  required bool enabled,
  required VoidCallback onTap,
}) => Material(
  color: selected ? YuntaColors.surfaceBlue : YuntaColors.surfaceWhite,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(
      color: selected ? YuntaColors.primary : YuntaColors.outlineSoft,
    ),
  ),
  child: InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: YuntaColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Radio<String>(value: value),
        ],
      ),
    ),
  ),
);

Widget postTypeHeading(
  BuildContext context,
  PostTypeDefinition type, {
  required bool emergency,
}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: YuntaColors.surfaceWhite,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
  ),
  child: Row(
    children: [
      Icon(
        type.icon,
        size: 28,
        color: emergency ? YuntaColors.danger : YuntaColors.primary,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.category.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              type.publishLabel ?? type.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      if (emergency)
        const Chip(
          label: Text('Emergencia'),
          avatar: Icon(Icons.warning_amber_rounded, size: 18),
          backgroundColor: YuntaColors.dangerSoft,
          labelStyle: TextStyle(color: YuntaColors.danger),
        ),
    ],
  ),
);

bool containsPhoneNumber(String text) =>
    RegExp(r'(?<!\d)(?:\+?51[\s-]?)?9\d{2}[\s-]?\d{3}[\s-]?\d{3}(?!\d)')
        .hasMatch(text);
