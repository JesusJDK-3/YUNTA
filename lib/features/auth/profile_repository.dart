import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/location_point.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<RegisteredProfile?> getMyProfile() async {
    final result = await _client.rpc('get_my_profile');
    if (result == null) return null;
    final profile = Map<String, dynamic>.from(result as Map);
    final latitude = profile['latitude'] as num?;
    final longitude = profile['longitude'] as num?;
    if (latitude == null || longitude == null) {
      throw const FormatException('El perfil no tiene una ubicación válida.');
    }
    return RegisteredProfile(
      displayName: profile['display_name'] as String,
      location: LocationPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
      locationSource: profile['location_source'] as String? ?? 'manual',
      ratingAverage: (profile['rating_average'] as num?)?.toDouble() ?? 0,
      ratingCount: (profile['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> saveRegistration({
    required String displayName,
    required String phoneE164,
    required LocationPoint location,
    required String locationSource,
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
        'p_tutorial_completed': false,
      },
    );
  }

  Future<void> updateLocation({
    required LocationPoint location,
    required String locationSource,
  }) async {
    await _client.rpc(
      'update_my_location',
      params: {
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_location_source': locationSource,
      },
    );
  }
}

class RegisteredProfile {
  const RegisteredProfile({
    required this.displayName,
    required this.location,
    required this.locationSource,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  final String displayName;
  final LocationPoint location;
  final String locationSource;
  final double ratingAverage;
  final int ratingCount;
}
