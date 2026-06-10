import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vault_os/src/models/activity_log_model.dart';
import 'package:vault_os/src/services/supabase_service.dart';
import 'package:vault_os/src/features/settings/providers.dart';

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository(this._supabase);

  Future<List<ActivityLog>> getRecentLogs(String userId) async {
    final response = await _supabase
        .from('activity_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(5);

    return (response as List).map((json) => ActivityLog.fromJson(json)).toList();
  }

  Future<List<ActivityLog>> getFullLogs(String userId) async {
    final response = await _supabase
        .from('activity_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ActivityLog.fromJson(json)).toList();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(SupabaseService.client);
});

final recentLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return [];
  
  final logs = await repository.getRecentLogs(userId);
  // User asked for limit 4 in the main screen, but repository fetches 5.
  // We'll take first 4 as requested in UI implementation.
  return logs.take(4).toList();
});

final fullLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return [];

  return repository.getFullLogs(userId);
});
