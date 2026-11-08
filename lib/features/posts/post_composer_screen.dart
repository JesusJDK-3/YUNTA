import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import '../auth/location_picker_screen.dart';
import 'post_catalog.dart';
import 'post_composer_sections.dart';
import 'post_image_attachment.dart';
import 'post_repository.dart';

enum PostPublishResult { published, photoUploadFailed }

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
  XFile? _selectedImage;
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
      final repository = PostRepository(Supabase.instance.client);
      await repository.createPost(
        id: _postId,
        category: widget.type.category.databaseValue,
        type: widget.type.value,
        title: _title.text,
        description: _description.text,
        coordinationMode: _coordinationMode,
        latitude: _location.latitude,
        longitude: _location.longitude,
      );
      if (_selectedImage != null) {
        try {
          await repository.attachImage(_postId, _selectedImage!);
        } catch (_) {
          if (mounted) {
            Navigator.of(context).pop(PostPublishResult.photoUploadFailed);
          }
          return;
        }
      }
      if (mounted) Navigator.of(context).pop(PostPublishResult.published);
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
                postTypeHeading(context, widget.type, emergency: _emergency),
                const SizedBox(height: 18),
                composerSection(
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
                          if (containsPhoneNumber(text)) {
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
                          if (containsPhoneNumber(text)) {
                            return 'No publiques celulares; compártelos por el chat.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      PostImageAttachment(
                        enabled: !_saving,
                        onChanged: (image) => _selectedImage = image,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                composerSection(
                  context,
                  title: '¿Cómo quieres coordinar?',
                  icon: Icons.groups_outlined,
                  child: RadioGroup<String>(
                    groupValue: _coordinationMode,
                    onChanged: (value) {
                      if (!_saving && !_fixedGroup && value != null) {
                        setState(() => _coordinationMode = value);
                      }
                    },
                    child: Column(
                      children: [
                        if (!_fixedGroup) ...[
                          composerModeOption(
                            context,
                            value: 'individual',
                            title: 'Individual',
                            subtitle: 'Coordina en privado con un vecino.',
                            icon: Icons.person_outline,
                            selected: _coordinationMode == 'individual',
                            enabled: !_saving,
                            onTap: () => setState(
                              () => _coordinationMode = 'individual',
                            ),
                          ),
                          const SizedBox(height: 9),
                        ],
                        composerModeOption(
                          context,
                          value: 'group',
                          title: 'En grupo',
                          subtitle: _fixedGroup
                              ? 'Este aviso se coordina en grupo.'
                              : 'Varios vecinos comparten un chat.',
                          icon: Icons.groups_outlined,
                          selected: _coordinationMode == 'group',
                          enabled: !_saving && !_fixedGroup,
                          onTap: () =>
                              setState(() => _coordinationMode = 'group'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                composerSection(
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
}
