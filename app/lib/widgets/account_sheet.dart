import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/yunta_exception.dart';

/// Nombre y zona son los datos con los que el barrio te ve.
/// El GPS solo propone una zona. El punto no se escribe en el perfil.
Future<void> showAccountSheet(BuildContext context, AppState app, List<BlockView> blocks) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AccountSheet(app: app, blocks: List<BlockView>.from(blocks)),
  );
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({required this.app, required this.blocks});
  final AppState app;
  final List<BlockView> blocks;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.app.session?.displayName ?? '');
  late String _zoneId = widget.app.session?.zoneId ?? kZones.first.id;
  late List<BlockView> _blocks = widget.blocks;
  String? _hint;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    setState(() => _error = null);
    await widget.app.askPlace();
    if (!mounted) return;
    final point = widget.app.point;
    setState(() {
      if (point != null) {
        _zoneId = nearestZone(point.lat, point.lng);
        _hint = 'Sugerimos esta zona. Confírmala antes de guardar. El punto no se guarda.';
      } else {
        _error = 'No se pudo usar la ubicación. Elige la zona en la lista.';
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.app.api.saveProfile(_name.text, _zoneId);
      widget.app.setSession(session);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = asYunta(error).text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: ListView(
        children: [
          Text('Mis datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nombre para mostrar'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _zoneId,
            decoration: const InputDecoration(labelText: 'Zona'),
            items: [
              for (final zone in kZones) DropdownMenuItem(value: zone.id, child: Text(zone.name)),
            ],
            onChanged: _busy ? null : (value) => setState(() => _zoneId = value ?? _zoneId),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy || widget.app.placeStatus == PlaceStatus.loading ? null : _suggest,
            child: Text(widget.app.placeStatus == PlaceStatus.loading ? 'Buscando ubicación…' : 'Sugerir zona con mi ubicación'),
          ),
          if (_hint != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_hint!)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Guardar')),
          const SizedBox(height: 20),
          Text('Bloqueos', style: Theme.of(context).textTheme.titleMedium),
          if (_blocks.isEmpty) const Text('No has bloqueado a nadie.'),
          for (final block in _blocks)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  try {
                    await widget.app.api.unblock(block.userId);
                    if (mounted) setState(() => _blocks = _blocks.where((row) => row.userId != block.userId).toList());
                  } catch (error) {
                    if (mounted) setState(() => _error = asYunta(error).text);
                  }
                },
                child: Text('Desbloquear a ${block.displayName}'),
              ),
            ),
        ],
      ),
    );
  }
}
