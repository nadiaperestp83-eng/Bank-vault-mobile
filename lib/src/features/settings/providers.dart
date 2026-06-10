import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/models/profile_model.dart';
import 'package:vault_os/src/models/preferences_model.dart';
import 'package:vault_os/src/models/merchant_model.dart';
import 'package:vault_os/src/models/device_model.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:vault_os/src/models/receipt_model.dart';
import 'package:vault_os/src/services/settings_service.dart';
import 'package:vault_os/src/services/auth_service.dart';
import 'package:vault_os/src/services/dashboard_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

final profileStreamProvider = StreamProvider<Profile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return Stream.value(null);
  return settingsService.watchProfile(userId);
});

final preferencesStreamProvider = StreamProvider<UserPreferences?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return Stream.value(null);
  return settingsService.watchPreferences(userId);
});

final merchantsStreamProvider = StreamProvider<List<Merchant>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return Stream.value([]);
  return settingsService.watchMerchants(userId);
});

final devicesStreamProvider = StreamProvider<List<UserDevice>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final userId = authService.currentUser?.id;

  if (userId == null) return Stream.value([]);
  return settingsService.watchDevices(userId);
});

final notificationStreamProvider = StreamProvider<List<VaultNotification>>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getNotificationStream();
});

final receiptsStreamProvider = StreamProvider<List<VaultReceipt>>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getReceiptsStream();
});
