import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_repository.dart';

class PostRatingScreen extends StatefulWidget {
  const PostRatingScreen({
    required this.postId,
    required this.title,
    required this.providerName,
    super.key,
  });

  final String postId;
  final String title;
  final String providerName;

  @override
  State<PostRatingScreen> createState() => _PostRatingScreenState();
}

class _PostRatingScreenState extends State<PostRatingScreen> {
  final _comment = TextEditingController();
  int _score = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0 || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PostRepository(Supabase.instance.client).rateProvider(
        postId: widget.postId,
        score: _score,
        comment: _comment.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Califica a quien te ayudó')),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton.icon(
          onPressed: _score == 0 || _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Guardando…' : 'Enviar valoración'),
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: YuntaColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: YuntaColors.outlineSoft),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                        color: YuntaColors.surfaceMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_outlined,
                        size: 38,
                        color: YuntaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Califica a quien te ayudó',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Cuéntanos cómo fue la ayuda de '
                      '${widget.providerName}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YuntaColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AVISO RESUELTO'),
                          const SizedBox(height: 5),
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Valoración: $_score de 5 estrellas',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var star = 1; star <= 5; star++)
                            IconButton(
                              tooltip:
                                  '$star ${star == 1 ? 'estrella' : 'estrellas'}',
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _score = star),
                              iconSize: 42,
                              color: YuntaColors.actionPressed,
                              icon: Icon(
                                star <= _score
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _score == 0
                          ? 'Elige de 1 a 5 estrellas'
                          : '$_score de 5 estrellas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                enabled: !_saving,
                maxLength: 500,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Cuéntanos algo sobre tu experiencia',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: YuntaColors.danger),
                ),
              ],
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
