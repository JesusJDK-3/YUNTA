import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/yunta_exception.dart';
import '../widgets/chrome.dart';

/// Entrada por enlace mágico. El teléfono como proveedor de acceso está apagado en Supabase.
class EnterPage extends StatefulWidget {
  const EnterPage({super.key, required this.app});
  final AppState app;

  @override
  State<EnterPage> createState() => _EnterPageState();
}

class _EnterPageState extends State<EnterPage> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  List<ZoneOption> _zones = kZones;
  String _zoneId = kZones.first.id;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final rows = await widget.app.api.listZones();
      if (!mounted || rows.isEmpty) return;
      setState(() {
        _zones = rows;
        if (!rows.any((zone) => zone.id == _zoneId)) _zoneId = rows.first.id;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = asYunta(error).text);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.app.api.requestMagicLink(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = asYunta(error).text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.app.api.saveProfile(_name.text, _zoneId);
      widget.app.setSession(session);
    } catch (error) {
      if (mounted) setState(() => _error = asYunta(error).text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.app.pendingEmail;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Wordmark(),
            const SizedBox(height: 16),
            Text('Hola, vecino', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Oficios, favores y emergencias de tu zona. La casa no se publica.'),
            const SizedBox(height: 16),
            if (widget.app.notice != null) NoticeBanner(widget.app.notice!),
            if (_error != null) NoticeBanner(_error!, alert: true),
            if (pending != null) ...[
              Text('Entras como $pending. Elige cómo te verán.'),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nombre para mostrar'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _zoneId,
                decoration: const InputDecoration(labelText: 'Zona'),
                items: [
                  for (final zone in _zones) DropdownMenuItem(value: zone.id, child: Text(zone.name)),
                ],
                onChanged: _busy ? null : (value) => setState(() => _zoneId = value ?? _zoneId),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _saveProfile,
                child: Text(_busy ? 'Entrando…' : 'Entrar a Yunta'),
              ),
            ] else ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                maxLength: 254,
                decoration: const InputDecoration(labelText: 'Correo'),
                onChanged: (_) => setState(() => _sent = false),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _sendLink,
                child: Text(_busy ? 'Enviando…' : _sent ? 'Enviar de nuevo' : 'Entrar a Yunta'),
              ),
              if (_sent)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Revisa ese correo y abre el enlace en este celular. Si quieres otro, cámbialo y envía de nuevo.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
