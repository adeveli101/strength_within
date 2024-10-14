import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constant keys
const String appVersionKey = "appVersion";
const String firstRunDateKey = "firstRunDate";
const String weeklyAmountKey = "weeklyAmount";
const String lastSyncDateKey = "lastSyncDate";

class SharedPrefsProvider {
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> get sharedPreferences async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  Future<void> prepareData() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final SharedPreferences prefs = await sharedPreferences;

    if (prefs.getString(firstRunDateKey) == null) {
      final String dateStr = DateTime.now().toIso8601String();
      await prefs.setString(firstRunDateKey, dateStr);
      await prefs.setDouble(weeklyAmountKey, 3.0);
    }

    final String? storedVersion = prefs.getString(appVersionKey);
    if (storedVersion == null || storedVersion != packageInfo.version) {
      await prefs.setString(appVersionKey, packageInfo.version);
    }
  }

  Future<double> getWeeklyAmount() async {
    final SharedPreferences prefs = await sharedPreferences;
    return prefs.getDouble(weeklyAmountKey) ?? 3.0;
  }

  Future<void> setWeeklyAmount(double amt) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setDouble(weeklyAmountKey, amt);
  }

  Future<DateTime?> getFirstRunDate() async {
    final SharedPreferences prefs = await sharedPreferences;
    final String? dateStr = prefs.getString(firstRunDateKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  Future<void> setLastSyncDate(DateTime date) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setString(lastSyncDateKey, date.toIso8601String());
  }

  Future<DateTime?> getLastSyncDate() async {
    final SharedPreferences prefs = await sharedPreferences;
    final String? dateStr = prefs.getString(lastSyncDateKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
}

final sharedPrefsProvider = SharedPrefsProvider();