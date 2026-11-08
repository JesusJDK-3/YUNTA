import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/device_location.dart';
import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';
import 'location_picker_screen.dart';
import 'profile_repository.dart';
import 'registration_footer_widgets.dart';
import 'registration_sections.dart';
import 'registration_tutorial_screen.dart';

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
    setState(() {
      _busy = true;
      _locationError = null;
    });
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
          RegisteredProfile(
            displayName: _name.text.trim(),
            location: _point!,
            locationSource: _source,
          ),
        );
      }
    } on AuthException {
      _showSaveError('No se pudo crear tu sesión. Revisa tu conexión.');
    } on PostgrestException {
      _showSaveError('No se pudo guardar tu perfil. Inténtalo de nuevo.');
    } catch (_) {
      _showSaveError('No se pudo completar el registro. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSaveError(String message) {
    if (mounted) setState(() => _locationError = message);
  }

  void _openTutorial() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const RegistrationTutorialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: YuntaColors.registrationCanvas,
    bottomNavigationBar: RegistrationFooter(
      busy: _busy,
      onSubmit: _submit,
      onTutorial: _openTutorial,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RegistrationHero(),
                  const SizedBox(height: 21),
                  RegistrationPanel(
                    title: 'Tu perfil vecinal',
                    icon: Icons.badge_outlined,
                    child: Column(
                      children: [
                        _nameField(),
                        const SizedBox(height: 15),
                        _phoneField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RegistrationLocationPanel(
                    point: _point,
                    source: _source,
                    locating: _locating,
                    busy: _busy,
                    onUseGps: _useGps,
                    onChooseMap: _chooseOnMap,
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 11),
                    _locationFeedback(),
                  ],
                  const SizedBox(height: 14),
                  const RegistrationPrivacyBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nameField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldCaption('Tu nombre visible', 'Público en el radio'),
      const SizedBox(height: 7),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        maxLength: 60,
        decoration: const InputDecoration(
          filled: true,
          fillColor: YuntaColors.registrationField,
          prefixIcon: Icon(Icons.person_outline_rounded),
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
      _fieldCaption('Número de celular', 'Privado, sin SMS'),
      const SizedBox(height: 7),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RegistrationCountryCode(),
          const SizedBox(width: 9),
          Expanded(
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                filled: true,
                fillColor: YuntaColors.registrationField,
                hintText: '987 654 321',
                counterText: '',
              ),
              validator: (value) => RegExp(r'^9[0-9]{8}$').hasMatch(value ?? '')
                  ? null
                  : 'Escribe un celular peruano de 9 dígitos.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: YuntaColors.surfaceMint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 19,
              color: YuntaColors.primary,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Tu número es privado y seguro. Solo tú lo administras y '
                'nunca se muestra a otros vecinos.',
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _fieldCaption(String title, String trailing) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
      Text(trailing, style: Theme.of(context).textTheme.bodySmall),
    ],
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
