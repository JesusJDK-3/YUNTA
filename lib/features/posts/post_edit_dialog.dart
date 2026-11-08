import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class PostEditDialog extends StatefulWidget {
  const PostEditDialog({
    required this.title,
    required this.description,
    required this.onSave,
    super.key,
  });

  final String title;
  final String description;
  final Future<void> Function(String title, String description) onSave;

  @override
  State<PostEditDialog> createState() => _PostEditDialogState();
}

class _PostEditDialogState extends State<PostEditDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.title);
    _description = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.length < 4 || title.length > 100 || description.length < 8) {
      setState(() => _error = 'Revisa el título y la descripción.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(title, description);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el anuncio.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar anuncio'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            maxLength: 1200,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: YuntaColors.danger)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Guardando…' : 'Guardar'),
      ),
    ],
  );
}
