import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/ids.dart';
import '../domain/choices.dart';
import '../domain/models.dart';
import '../domain/yunta_exception.dart';

/// Publicar cabe en tres toques: abrir, elegir y confirmar.
/// Escribir el título no es un toque más: el campo ya recibe el foco.
/// El identificador nace al abrir y no cambia si la persona reintenta.
Future<String?> showPublishSheet(BuildContext context, AppState app) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PublishSheet(app: app),
  );
}

class _PublishSheet extends StatefulWidget {
  const _PublishSheet({required this.app});
  final AppState app;

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  final _title = TextEditingController();
  final _detail = TextEditingController();
  final _area = TextEditingController();
  final _titleFocus = FocusNode();
  late final String _requestId = newId();
  String _choiceId = kDefaultPublishChoice;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _area.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final choice = publishChoice(_choiceId);
    final point = widget.app.point;
    try {
      final created = await widget.app.api.publish(PublishInput(
        intent: choice.intent,
        helpType: choice.helpType,
        title: _title.text,
        description: _detail.text,
        areaLabel: _area.text.trim().isEmpty ? null : _area.text,
        lat: point?.lat,
        lng: point?.lng,
        clientRequestId: _requestId,
      ));
      if (mounted) Navigator.of(context).pop(created.id);
    } catch (error) {
      if (mounted) setState(() => _error = asYunta(error).text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.app.point;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: ListView(
        children: [
          Text('Publicar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _choiceId,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _choiceId = value);
              _titleFocus.requestFocus();
              final choice = publishChoice(value);
              if (choice.intent.startsWith('emergencia') && widget.app.point == null) {
                widget.app.askPlace();
              }
            },
            child: Column(
              children: [
                for (final group in const [
                  ('favor', 'Favor'),
                  ('directorio', 'Oficio o producto'),
                  ('emergencia', 'Emergencia'),
                ]) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(group.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  for (final choice in kPublishChoices.where((item) => item.group == group.$1))
                    RadioListTile<String>(
                      value: choice.id,
                      title: Text(choice.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ],
            ),
          ),
          TextField(
            controller: _title,
            focusNode: _titleFocus,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          TextField(
            controller: _detail,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Detalle'),
          ),
          TextField(
            controller: _area,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Referencia visible',
              hintText: 'Ej. cerca del mercado',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Abrir, elegir y publicar. Escribir el título no suma un toque. '
            '${point == null ? 'Sin ubicación, el aviso usa el centro de tu zona.' : 'Tu ubicación aproxima el aviso y la dirección no se muestra.'}',
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Publicando…' : 'Publicar'),
          ),
        ],
      ),
    );
  }
}
