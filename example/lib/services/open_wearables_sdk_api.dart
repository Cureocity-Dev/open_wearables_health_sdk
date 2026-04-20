import 'package:open_wearables_health_sdk/open_wearables_health_sdk.dart';
import 'package:open_wearables_health_sdk/health_data_type.dart';

/// Thin forwarding wrapper around the static `OpenWearablesHealthSdk`. Exists
/// solely so the service layer can inject a mock in unit tests.
class OpenWearablesSdkApi {
  const OpenWearablesSdkApi();

  Future<void> configure({required String host}) =>
      OpenWearablesHealthSdk.configure(host: host);

  Future<OpenWearablesHealthSdkUser> signIn({
    required String userId,
    String? accessToken,
    String? refreshToken,
    String? apiKey,
  }) =>
      OpenWearablesHealthSdk.signIn(
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        apiKey: apiKey,
      );

  Future<void> signOut() => OpenWearablesHealthSdk.signOut();

  Future<void> updateTokens({required String accessToken, String? refreshToken}) =>
      OpenWearablesHealthSdk.updateTokens(
          accessToken: accessToken, refreshToken: refreshToken);

  Future<bool> requestAuthorization({required List<HealthDataType> types}) =>
      OpenWearablesHealthSdk.requestAuthorization(types: types);

  Future<void> syncNow() => OpenWearablesHealthSdk.syncNow();

  Future<bool> startBackgroundSync({int? syncDaysBack}) =>
      OpenWearablesHealthSdk.startBackgroundSync(syncDaysBack: syncDaysBack);

  Future<void> stopBackgroundSync() =>
      OpenWearablesHealthSdk.stopBackgroundSync();

  Future<void> resetAnchors() => OpenWearablesHealthSdk.resetAnchors();

  Future<void> resumeSync() => OpenWearablesHealthSdk.resumeSync();

  Future<void> clearSyncSession() => OpenWearablesHealthSdk.clearSyncSession();

  Future<Map<String, dynamic>> getSyncStatus() =>
      OpenWearablesHealthSdk.getSyncStatus();

  Future<Map<String, dynamic>> getStoredCredentials() =>
      OpenWearablesHealthSdk.getStoredCredentials();

  Future<List<AvailableProvider>> getAvailableProviders() =>
      OpenWearablesHealthSdk.getAvailableProviders();

  Future<void> setProvider(AndroidHealthProvider provider) =>
      OpenWearablesHealthSdk.setProvider(provider);

  Future<void> setSyncNotification({String? title, String? text}) =>
      OpenWearablesHealthSdk.setSyncNotification(title: title, text: text);
}
