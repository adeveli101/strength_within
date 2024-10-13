import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_provider.dart';

// Constant keys
const String appVersionKey = "appVersion";
const String firstRunDateKey = "firstRunDate";
const String dailyRankKey = "dailyRank";
const String databaseStatusKey = "databaseStatus";
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
      await prefs.setBool(databaseStatusKey, false);
      await prefs.setInt(weeklyAmountKey, 3);
    }

    final String? storedVersion = prefs.getString(appVersionKey);
    if (storedVersion == null || storedVersion != packageInfo.version) {
      await prefs.setString(appVersionKey, packageInfo.version);
      firebaseProvider.isFirstRun = true;
    } else {
      firebaseProvider.isFirstRun = false;
    }

    firebaseProvider.firstRunDate = DateTime.tryParse(prefs.getString(firstRunDateKey) ?? '');
    firebaseProvider.weeklyAmount = prefs.getInt(weeklyAmountKey)?.toDouble() ?? 3.0;
  }

  Future<int> getDailyRank() async {
    final SharedPreferences prefs = await sharedPreferences;
    final String? dailyRankInfo = prefs.getString(dailyRankKey);
    if (dailyRankInfo == null) return 0;
    final DateTime lastWorkoutDate = DateTime.parse(dailyRankInfo.split('/').first).toLocal();
    if (DateTime.now().difference(lastWorkoutDate).inDays >= 1) return 0;
    return int.parse(dailyRankInfo.split('/')[1]);
  }

  Future<void> setWeeklyAmount(int amt) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setInt(weeklyAmountKey, amt);
    firebaseProvider.weeklyAmount = amt.toDouble();
  }

  Future<void> setDailyRankInfo(String dailyRankInfo) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setString(dailyRankKey, dailyRankInfo);
  }

  Future<void> setDatabaseStatus(bool dbStatus) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setBool(databaseStatusKey, dbStatus);
  }

  Future<bool?> getDatabaseStatus() async {
    final SharedPreferences prefs = await sharedPreferences;
    return prefs.getBool(databaseStatusKey);
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
