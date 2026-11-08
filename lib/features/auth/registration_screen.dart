import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/device_location.dart';
import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/ambient_bubbles.dart';
import '../../shared/widgets/yunta_wordmark.dart';
import 'location_picker_screen.dart';
import 'profile_repository.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({required this.onRegistered, super.key});

  final ValueChanged<RegisteredProfile> onRegistered;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  LocationPoint? _point;
  String _source = 'gps';
  String? _locationError;
  bool _settingsForDevice = false;
  bool _busy = false;
  bool _locating = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _locationError = null;
      _settingsForDevice = false;
    });
    try {
      final point = await DeviceLocation.current();
      if (!mounted) return;
      setState(() {
        _point = point;
        _source = 'gps';
        _settingsForDevice = false;
      });
    } on LocationAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error.message;
        _settingsForDevice = error.deviceSettings;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationError =
              'No se pudo obtener la ubicación. Inténtalo de nuevo.',
        );
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
      _locationError = null;
      _settingsForDevice = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_point == null) {
      setState(
        () => _locationError = 'Selecciona tu ubicación para continuar.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      await ProfileRepository(Supabase.instance.client).saveRegistration(
        displayName: _name.text.trim(),
        phoneE164: '+51$digits',
        location: _point!,
        locationSource: _source,
      );
      if (mounted) {
        widget.onRegistered(
          RegisteredProfile(displayName: _name.text.trim(), location: _point!),
        );
      }
    } on AuthException {
      _showSaveError('No se pudo crear tu sesión. Revisa tu conexión.');
    } on PostgrestException {
      _showSaveError(
        'No se pudo guardar tu perfil. Revisa los datos e inténtalo.',
      );
    } catch (_) {
      _showSaveError('No se pudo completar el registro. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSaveError(String message) {
    if (mounted) setState(() => _locationError = message);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const YuntaWordmark(),
                  const SizedBox(height: 30),
                  _welcome(context),
                  const SizedBox(height: 24),
                  _profileCard(),
                  const SizedBox(height: 16),
                  _locationSection(context),
                  if (_locationError != null) ...[
                    const SizedBox(height: 10),
                    _locationFeedback(),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(_busy ? 'Guardando…' : 'Entrar a Yunta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _profileCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline, color: YuntaColors.primary),
            const SizedBox(width: 8),
            Text('Tu perfil', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),
        _nameField(),
        const SizedBox(height: 14),
        _phoneField(),
      ],
    ),
  );

  Widget _welcome(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, vecino!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            const Text('Conecta con vecinos a 500 m de ti.'),
          ],
        ),
      ),
      const AmbientBubbles(),
    ],
  );

  Widget _nameField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FieldLabel('Tu nombre'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        maxLength: 60,
        decoration: const InputDecoration(
          hintText: '¿Cómo te llamas?',
          counterText: '',
        ),
        validator: (value) {
          final name = value?.trim() ?? '';
          if (name.length < 2) return 'Escribe al menos 2 caracteres.';
          if (name.length > 60) return 'Usa 60 caracteres o menos.';
          return null;
        },
      ),
    ],
  );

  Widget _phoneField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FieldLabel('Número de celular'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: const InputDecoration(
          prefixText: '+51  ',
          hintText: 'Escribe tu número',
        ),
        validator: (value) => RegExp(r'^9[0-9]{8}$').hasMatch(value ?? '')
            ? null
            : 'Escribe un celular peruano de 9 dígitos.',
      ),
      const SizedBox(height: 5),
      const Text('Tu número queda privado. No enviaremos SMS.'),
    ],
  );

  Widget _locationSection(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Ubicación'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useGps,
          icon: _locating
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_on_outlined),
          label: Text(_locating ? 'Buscando ubicación…' : 'Usar mi ubicación'),
        ),
        Center(
          child: TextButton(
            onPressed: _locating ? null : _chooseOnMap,
            child: const Text('Elegir en el mapa'),
          ),
        ),
        if (_point != null)
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: YuntaColors.success),
              SizedBox(width: 7),
              Text('Ubicación lista', style: TextStyle(color: YuntaColors.ink)),
            ],
          ),
        const SizedBox(height: 5),
        const Text(
          'Tu ubicación exacta es privada. Se usa para encontrar avisos cercanos.',
        ),
      ],
    ),
  );

  Widget _locationFeedback() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_locationError!, style: const TextStyle(color: YuntaColors.danger)),
      if (_settingsForDevice)
        TextButton.icon(
          onPressed: () => DeviceLocation.openSettings(device: true),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Abrir ajustes de ubicación'),
        )
      else if (_locationError!.contains('bloqueado'))
        TextButton.icon(
          onPressed: () => DeviceLocation.openSettings(),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Abrir ajustes de la app'),
        ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}
