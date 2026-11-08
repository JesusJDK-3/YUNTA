import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/location_point.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getMyProfile() async {
    final result = await _client.rpc('get_my_profile');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
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
}
