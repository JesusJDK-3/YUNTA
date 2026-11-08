import 'package:flutter/material.dart';

import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/ambient_bubbles.dart';
import 'registration_location_preview.dart';

class RegistrationHero extends StatelessWidget {
  const RegistrationHero({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 126,
        height: 118,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: AmbientBubbles()),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: YuntaColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: YuntaColors.registrationSky,
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A001F2A),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/yunta-192.png',
                  width: 66,
                  height: 66,
                  semanticLabel: 'Yunta, logotipo con la letra Y',
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: YuntaColors.action,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: YuntaColors.inkStrong,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: YuntaColors.registrationSky,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: YuntaColors.actionPressed),
            SizedBox(width: 7),
            Text('Comunidad de ayuda mutua'),
          ],
        ),
      ),
      const SizedBox(height: 15),
      Text(
        '¡Hola, vecino!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 5),
      const Text(
        'Conecta con tu comunidad inmediata en un radio de 500 metros.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class RegistrationPanel extends StatelessWidget {
  const RegistrationPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12001F2A),
          offset: Offset(0, 4),
          blurRadius: 9,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: YuntaColors.primary, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 17),
        child,
      ],
    ),
  );
}

class RegistrationLocationPanel extends StatelessWidget {
  const RegistrationLocationPanel({
    required this.point,
    required this.source,
    required this.locating,
    required this.busy,
    required this.onUseGps,
    required this.onChooseMap,
    super.key,
  });

  final LocationPoint? point;
  final String source;
  final bool locating;
  final bool busy;
  final VoidCallback onUseGps;
  final VoidCallback onChooseMap;

  String get _status => point == null
      ? 'Pendiente'
      : source == 'gps'
      ? 'GPS activo'
      : 'Punto del mapa';

  @override
  Widget build(BuildContext context) => RegistrationPanel(
    title: 'Zona vecinal asignada',
    icon: Icons.near_me_outlined,
    trailing: _StatusPill(label: _status, selected: point != null),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _InfoPill(icon: Icons.radar_rounded, label: 'Radio de 500 m'),
            _InfoPill(icon: Icons.shield_outlined, label: 'Ubicación privada'),
          ],
        ),
        const SizedBox(height: 12),
        if (point == null)
          Container(
            height: 128,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: YuntaColors.registrationField,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_searching,
                  size: 30,
                  color: YuntaColors.primary,
                ),
                SizedBox(height: 7),
                Text('Elige tu ubicación para ver el radio.'),
              ],
            ),
          )
        else
          RegistrationLocationPreview(point: point!),
        const SizedBox(height: 13),
        OutlinedButton.icon(
          onPressed: locating || busy ? null : onUseGps,
          icon: locating
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(
            locating
                ? 'Buscando ubicación…'
                : point != null && source == 'gps'
                ? 'Actualizar ubicación GPS'
                : 'Usar mi ubicación actual',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: locating || busy ? null : onChooseMap,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Ajustar punto aproximado en el mapa'),
        ),
      ],
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: YuntaColors.registrationSky,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: YuntaColors.primary),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? YuntaColors.registrationSky : YuntaColors.surfaceMint,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? Icons.circle : Icons.radio_button_unchecked,
          size: 10,
          color: selected ? YuntaColors.primary : YuntaColors.muted,
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}
