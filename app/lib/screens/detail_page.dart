import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/ids.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/yunta_exception.dart';
import '../widgets/chrome.dart';

/// Ficha de un aviso o un caso. El chat se vuelve a leer si llega un mensaje
/// o cada 8 segundos con la pantalla abierta. No guarda el punto.
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.app, required this.id});
  final AppState app;
  final String id;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Detail? _detail;
  String? _error;
  String? _info;
  bool _busy = false;
  final _message = TextEditingController();
  final _reason = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  var _score = 5;
  var _hydrated = false;
  Timer? _timer;
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _load();
    _unsubscribe = widget.app.api.subscribeMessages(widget.id, _load);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unsubscribe?.call();
    _message.dispose();
    _reason.dispose();
    _phone.dispose();
    _comment.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final next = await widget.app.api.detail(widget.id);
      if (!mounted) return;
      // El sondeo de 8 segundos no redibuja si el chat no cambió.
      if (_detail != null && _detailStamp(_detail!) == _detailStamp(next) && _error == null) return;
      setState(() {
        _detail = next;
        if (!_hydrated) {
          _hydrated = true;
          _title.text = next.item.title;
          _description.text = next.item.description;
        }
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = asYunta(error).text);
    }
  }

  Future<void> _run(Future<void> Function() action, [String? ok]) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
      if (mounted && ok != null) setState(() => _info = ok);
    } catch (error) {
      if (mounted) setState(() => _error = asYunta(error).text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final body = _message.text;
    _message.clear();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.app.api.sendMessage(widget.id, body);
      final next = await widget.app.api.detail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = next;
        if (next.messages.any((entry) => entry.pending && entry.body == body)) {
          _info = 'Sin conexión. El mensaje quedó en este celular y se enviará al volver la señal.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message.text = body;
        _error = asYunta(error).text;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aviso')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error ?? 'Cargando el aviso…'),
        ),
      );
    }
    final item = detail.item;
    final userId = widget.app.session?.userId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${item.authorName} · ${item.areaLabel}'
            '${item.distanceLabel == null ? '' : ' · ${item.distanceLabel}'}',
          ),
          Text([modeLabel(item.coordinationMode), statusLabel(item.status)].whereType<String>().join(' · ')),
          if (item.category == 'emergencia') const Text('Emergencia'),
          if (detail.offline)
            const NoticeBanner('Sin conexión. Ves la última ficha guardada. El mensaje que escribas queda en este celular.'),
          const SizedBox(height: 8),
          Text(item.description),
          if (item.kind == 'anuncio' && item.recommendationCount > 0)
            Text('Recomendado por ${item.recommendationCount} vecinos de ${item.zoneName}.'),
          if (item.ratingAverage != null)
            Text('Valoración ${item.ratingAverage}, a partir de ${item.ratingCount} atenciones.'),
          if (detail.myStatus == 'pendiente') const NoticeBanner('Esperando que acepten. El chat se abre después.'),
          if (_error != null) NoticeBanner(_error!, alert: true),
          if (_info != null) NoticeBanner(_info!),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.canOfferHelp)
                FilledButton(onPressed: _busy ? null : () => _run(() => widget.app.api.requestEntry(widget.id)), child: const Text('Puedo ayudar')),
              if (detail.canRequestHelp)
                FilledButton(onPressed: _busy ? null : () => _run(() => widget.app.api.requestEntry(widget.id)), child: const Text('La necesito')),
              if (detail.canJoinGroup)
                FilledButton(onPressed: _busy ? null : () => _run(() => widget.app.api.joinGroup(widget.id)), child: const Text('Unirme')),
              if (item.kind == 'anuncio' && !detail.isAuthor)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            final created = await widget.app.api.coordinate(widget.id, newId());
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                              builder: (_) => DetailPage(app: widget.app, id: created.id),
                            ));
                          } catch (error) {
                            if (mounted) setState(() => _error = asYunta(error).text);
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: const Text('Quiero coordinar'),
                ),
              if (detail.canRecommend)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => widget.app.api.recommend(widget.id), 'Listo. Tu visto bueno quedó en el anuncio.'),
                  child: const Text('Recomendar'),
                ),
              if (detail.canResolve)
                OutlinedButton(onPressed: _busy ? null : () => _run(() => widget.app.api.resolve(widget.id)), child: const Text('Marcar resuelto')),
              if (detail.canReopen)
                OutlinedButton(onPressed: _busy ? null : () => _run(() => widget.app.api.reopen(widget.id)), child: const Text('Reabrir')),
              if (detail.canCancel)
                TextButton(
                  onPressed: _busy ? null : () => _run(() => widget.app.api.cancel(widget.id)),
                  child: Text(item.kind == 'anuncio' ? 'Retirar anuncio' : 'Cancelar'),
                ),
            ],
          ),
          if (detail.alreadyRecommended) const Text('Ya recomendaste este anuncio.'),
          if (detail.pending.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Solicitudes', style: Theme.of(context).textTheme.titleMedium),
            for (final person in detail.pending)
              Row(
                children: [
                  Expanded(child: Text(person.displayName)),
                  TextButton(onPressed: _busy ? null : () => _run(() => widget.app.api.accept(widget.id, person.userId)), child: const Text('Aceptar')),
                  TextButton(onPressed: _busy ? null : () => _run(() => widget.app.api.reject(widget.id, person.userId)), child: const Text('Rechazar')),
                ],
              ),
          ],
          if (detail.canEdit) ...[
            const SizedBox(height: 16),
            Text('Editar anuncio', style: Theme.of(context).textTheme.titleMedium),
            TextField(controller: _title, maxLength: 80, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: _description, maxLength: 500, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Detalle')),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => widget.app.api.editAnuncio(widget.id, _title.text, _description.text), 'Anuncio actualizado.'),
              child: const Text('Guardar'),
            ),
          ],
          if (detail.members.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('En este caso', style: Theme.of(context).textTheme.titleMedium),
            for (final person in detail.members)
              Row(
                children: [
                  Expanded(child: Text(person.displayName)),
                  if (item.coordinationMode == 'grupal' && detail.isAuthor && person.userId != item.authorId)
                    TextButton(
                      onPressed: _busy ? null : () => _run(() => widget.app.api.removeMember(widget.id, person.userId)),
                      child: const Text('Sacar'),
                    ),
                ],
              ),
          ],
          if (detail.chatOpen) ...[
            const SizedBox(height: 16),
            Text('Chat del caso', style: Theme.of(context).textTheme.titleMedium),
            if (detail.messages.isEmpty) const Text('Todavía no hay mensajes.'),
            for (final entry in detail.messages)
              Align(
                alignment: entry.pending || entry.senderId == userId ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: entry.pending || entry.senderId == userId ? const Color(0xFFFFF3C5) : const Color(0xFFF3F6F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.senderName}. ${entry.body}'
                    '${entry.pending ? ' Pendiente de envío.' : ''}',
                  ),
                ),
              ),
            if (detail.canSend) ...[
              TextField(
                controller: _message,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                onChanged: (_) => setState(() {}),
              ),
              FilledButton(
                onPressed: _busy || _message.text.trim().isEmpty ? null : _send,
                child: const Text('Enviar'),
              ),
            ] else
              const Text('El chat queda para consulta.'),
            if (detail.canSharePhone) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 16,
                decoration: const InputDecoration(labelText: 'Compartir mi número', hintText: '+51987654321'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => widget.app.api.sharePhone(widget.id, _phone.text), 'Número compartido solo en este chat.'),
                child: const Text('Enviar número a este chat'),
              ),
            ],
          ],
          if (detail.canRate) ...[
            const SizedBox(height: 16),
            Text('Valorar a quien ayudó', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<int>(
              initialValue: _score,
              decoration: const InputDecoration(labelText: 'Nota de 1 a 5'),
              items: [for (var n = 1; n <= 5; n++) DropdownMenuItem(value: n, child: Text('$n'))],
              onChanged: (value) => setState(() => _score = value ?? _score),
            ),
            TextField(controller: _comment, maxLength: 280, decoration: const InputDecoration(labelText: 'Comentario, si quieres')),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => widget.app.api.rate(widget.id, _score, _comment.text),
                        'Gracias. La nota se publica desde la tercera valoración.',
                      ),
              child: const Text('Valorar'),
            ),
          ],
          if (detail.myRating != null) Text('Tu valoración: ${detail.myRating!.score}.'),
          if (!detail.isAuthor) ...[
            const SizedBox(height: 16),
            Text('Reportar', style: Theme.of(context).textTheme.titleMedium),
            TextField(controller: _reason, maxLength: 200, decoration: const InputDecoration(labelText: 'Qué pasó')),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () => widget.app.api.report('publicacion', widget.id, _reason.text),
                            'Reporte registrado. Quien publicó no ve tu nombre.',
                          ),
                  child: const Text('Reportar'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => widget.app.api.block(item.authorId), 'Bloqueado. Ya no verás sus avisos.'),
                  child: const Text('Bloquear'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _detailStamp(Detail detail) {
  final last = detail.messages.isEmpty ? null : detail.messages.last;
  return '${detail.item.status}|${detail.item.title}|${detail.messages.length}|${last?.id ?? ''}|${last?.body ?? ''}|${detail.pending.length}|${detail.members.length}|${detail.chatOpen}|${detail.canSend}';
}
