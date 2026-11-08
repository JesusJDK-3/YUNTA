import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/device_location.dart';
import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import 'location_picker_screen.dart';
import 'profile_repository.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({required this.profile, super.key});

  final RegisteredProfile profile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late LocationPoint _point;
  late String _source;
  String? _error;
  var _busy = false;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _phone = TextEditingController(text: _localPhone(widget.profile.phoneE164));
    _point = widget.profile.location;
    _source = widget.profile.locationSource;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _localPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('51') && digits.length == 11) {
      return digits.substring(2);
    }
    return digits;
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final point = await DeviceLocation.current();
      if (!mounted) return;
      setState(() {
        _point = point;
        _source = 'gps';
      });
    } on LocationAccessException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo obtener la ubicación.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final point = await Navigator.of(context).push<LocationPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPoint: _point),
      ),
    );
    if (point == null || !mounted) return;
    setState(() {
      _point = point;
      _source = 'manual';
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final next = widget.profile.copyWith(
      displayName: _name.text.trim(),
      phoneE164: '+51$digits',
      location: _point,
      locationSource: _source,
    );
    try {
      await ProfileRepository(Supabase.instance.client).saveProfile(
        displayName: next.displayName,
        phoneE164: next.phoneE164,
        location: next.location,
        locationSource: next.locationSource,
        tutorialCompleted: next.tutorialCompleted,
      );
      if (mounted) Navigator.of(context).pop(next);
    } on AuthException {
      _show('No se pudo actualizar la sesión. Revisa tu conexión.');
    } on PostgrestException {
      _show('No se pudo guardar el perfil. Revisa los datos.');
    } catch (_) {
      _show('No se pudo guardar el perfil. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tu perfil')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nombre visible'),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.length < 2) return 'Escribe al menos 2 caracteres.';
                if (name.length > 60) return 'Usa 60 caracteres o menos.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                labelText: 'Celular',
                prefixText: '+51 ',
              ),
              validator: (value) => RegExp(r'^9[0-9]{8}$').hasMatch(value ?? '')
                  ? null
                  : 'Escribe un celular peruano de 9 dígitos.',
            ),
            const SizedBox(height: 18),
            Text(
              _source == 'gps' ? 'Ubicación por GPS' : 'Ubicación del mapa',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || _locating ? null : _useGps,
              icon: const Icon(Icons.my_location),
              label: Text(_locating ? 'Buscando…' : 'Usar GPS'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || _locating ? null : _chooseOnMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ajustar en el mapa'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: YuntaColors.danger)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Guardando…' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    ),
  );
}
