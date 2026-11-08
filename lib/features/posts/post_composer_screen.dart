import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import '../auth/location_picker_screen.dart';
import 'post_catalog.dart';
import 'post_repository.dart';

class PostComposerScreen extends StatefulWidget {
  const PostComposerScreen({
    required this.type,
    required this.initialLocation,
    super.key,
  });

  final PostTypeDefinition type;
  final LocationPoint initialLocation;

  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _postId = const Uuid().v4();
  late LocationPoint _location;
  String _coordinationMode = 'individual';
  String? _error;
  bool _saving = false;

  bool get _fixedGroup => widget.type.groupOnly;
  bool get _emergency => widget.type.category == PostCategory.emergency;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
    if (_fixedGroup) _coordinationMode = 'group';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseLocation() async {
    final point = await Navigator.of(context).push<LocationPoint>(
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialPoint: _location, isPostLocation: true),
      ),
    );
    if (point != null && mounted) setState(() => _location = point);
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PostRepository(Supabase.instance.client).createPost(
        id: _postId,
        category: widget.type.category.databaseValue,
        type: widget.type.value,
        title: _title.text,
        description: _description.text,
        coordinationMode: _coordinationMode,
        latitude: _location.latitude,
        longitude: _location.longitude,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo publicar el aviso. Revisa los datos y tu conexión, '
              'e inténtalo de nuevo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo publicar. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo aviso')),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: YuntaColors.surfaceWhite,
          border: Border(top: BorderSide(color: YuntaColors.outlineSoft)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: YuntaColors.danger)),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'Publicando…' : 'Publicar aviso'),
            ),
          ],
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _typeHeading(context),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  title: 'Cuéntales a tus vecinos',
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: '¿Qué necesitas o compartes?',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 4) {
                            return 'Escribe al menos 4 caracteres.';
                          }
                          if (_containsPhone(text)) {
                            return 'No publiques celulares; compártelos por el chat.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 1200,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1200),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          alignLabelWithHint: true,
                          hintText: 'Añade detalles importantes…',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 8) {
                            return 'Escribe al menos 8 caracteres.';
                          }
                          if (_containsPhone(text)) {
                            return 'No publiques celulares; compártelos por el chat.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  context,
                  title: '¿Cómo quieres coordinar?',
                  icon: Icons.groups_outlined,
                  child: Column(
                    children: [
                      if (!_fixedGroup) ...[
                        _modeOption(
                          context,
                          value: 'individual',
                          title: 'Individual',
                          subtitle: 'Coordina en privado con un vecino.',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 9),
                      ],
                      _modeOption(
                        context,
                        value: 'group',
                        title: 'En grupo',
                        subtitle: _fixedGroup
                            ? 'Este aviso se coordina en grupo.'
                            : 'Varios vecinos comparten un chat.',
                        icon: Icons.groups_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  context,
                  title: 'Ubicación del aviso',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirma dónde necesitan encontrar este aviso.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _chooseLocation,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Elegir en el mapa'),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'En el muro solo se muestra una distancia aproximada; '
                        'tu punto exacto permanece privado.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _sectionCard(
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
            Icon(
              icon,
              color: _emergency ? YuntaColors.danger : YuntaColors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _modeOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _coordinationMode == value;
    final enabled = !_fixedGroup && !_saving;
    return Material(
      color: selected ? YuntaColors.surfaceBlue : YuntaColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? YuntaColors.primary : YuntaColors.outlineSoft,
        ),
      ),
      child: InkWell(
        onTap: enabled ? () => setState(() => _coordinationMode = value) : null,
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
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _coordinationMode,
                onChanged: enabled
                    ? (next) => setState(() => _coordinationMode = next!)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeHeading(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
    ),
    child: Row(
      children: [
        Icon(
          widget.type.icon,
          size: 28,
          color: _emergency ? YuntaColors.danger : YuntaColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.type.category.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                widget.type.publishLabel ?? widget.type.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (_emergency)
          const Chip(
            label: Text('Emergencia'),
            avatar: Icon(Icons.warning_amber_rounded, size: 18),
            backgroundColor: YuntaColors.dangerSoft,
            labelStyle: TextStyle(color: YuntaColors.danger),
          ),
      ],
    ),
  );

  bool _containsPhone(String text) =>
      RegExp(r'(?<!\d)(?:\+?51[\s-]?)?9\d{2}[\s-]?\d{3}[\s-]?\d{3}(?!\d)')
          .hasMatch(text);
}
