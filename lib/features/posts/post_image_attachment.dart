import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/yunta_theme.dart';

class PostImageAttachment extends StatefulWidget {
  const PostImageAttachment({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final ValueChanged<XFile?> onChanged;

  @override
  State<PostImageAttachment> createState() => _PostImageAttachmentState();
}

class _PostImageAttachmentState extends State<PostImageAttachment> {
  final _picker = ImagePicker();
  XFile? _image;
  String? _error;

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      if (await image.length() > 5 * 1024 * 1024) {
        setState(() => _error = 'La foto supera el límite de 5 MB.');
        return;
      }
      setState(() {
        _image = image;
        _error = null;
      });
      widget.onChanged(image);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo abrir esa foto.');
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Foto (opcional)', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 10),
      if (_image case final image?)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.file(
                File(image.path),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filledTonal(
                  onPressed: widget.enabled ? _removeImage : null,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Quitar foto',
                ),
              ),
            ],
          ),
        )
      else
        OutlinedButton.icon(
          onPressed: widget.enabled ? _chooseImage : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Agregar una foto'),
        ),
      if (_error != null) ...[
        const SizedBox(height: 6),
        Text(_error!, style: const TextStyle(color: YuntaColors.danger)),
      ],
    ],
  );
}
