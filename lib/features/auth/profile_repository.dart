import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/location_point.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<RegisteredProfile?> getMyProfile() async {
    final result = await _client.rpc('get_my_profile');
    if (result == null) return null;
    final profile = Map<String, dynamic>.from(result as Map);
    final latitude = profile['latitude'];
    final longitude = profile['longitude'];
    final displayName = profile['display_name'];
    final phone = profile['phone_e164'];
    if (latitude is! num || longitude is! num) {
      throw const FormatException('El perfil no tiene una ubicación válida.');
    }
    if (displayName is! String || displayName.trim().isEmpty) {
      throw const FormatException('El perfil no tiene un nombre válido.');
    }
    if (phone is! String || phone.isEmpty) {
      throw const FormatException('El perfil no tiene un celular válido.');
    }
    return RegisteredProfile(
      displayName: displayName,
      phoneE164: phone,
      location: LocationPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
      locationSource: profile['location_source'] as String? ?? 'manual',
      tutorialCompleted: profile['tutorial_completed_at'] != null,
    );
  }

  Future<void> saveProfile({
    required String displayName,
    required String phoneE164,
    required LocationPoint location,
    required String locationSource,
    required bool tutorialCompleted,
  }) async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    await _client.rpc(
      'save_my_profile',
      params: {
        'p_display_name': displayName.trim(),
        'p_phone_e164': phoneE164,
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_location_source': locationSource,
        'p_tutorial_completed': tutorialCompleted,
      },
    );
  }
}

class RegisteredProfile {
  const RegisteredProfile({
    required this.displayName,
    required this.phoneE164,
    required this.location,
    required this.locationSource,
    required this.tutorialCompleted,
  });

  final String displayName;
  final String phoneE164;
  final LocationPoint location;
  final String locationSource;
  final bool tutorialCompleted;

  RegisteredProfile copyWith({
    String? displayName,
    String? phoneE164,
    LocationPoint? location,
    String? locationSource,
    bool? tutorialCompleted,
  }) => RegisteredProfile(
    displayName: displayName ?? this.displayName,
    phoneE164: phoneE164 ?? this.phoneE164,
    location: location ?? this.location,
    locationSource: locationSource ?? this.locationSource,
    tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
  );
}
