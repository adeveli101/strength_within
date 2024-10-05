import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_provider.dart';



// Sabit anahtarlar
const String appVersionKey = "appVersion";
const String firstRunDateKey = "firstRunDate";
const String dailyRankKey = "dailyRank";
const String databaseStatusKey = "databaseStatus";
const String weeklyAmountKey = "weeklyAmount";
const String credentialKey = "credentialKey";
const String emailKey = "emailKey";
const String passwordKey = "passwordKey";
const String gmailKey = "gmailKey";
const String gmailPasswordKey = "gmailPasswordKey";
const String signInMethodKey = "signInMethodKey";

enum SignInMethod { apple, google, none }

class SharedPrefsProvider {
  SharedPreferences? _sharedPreferences;
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  // Şifreleme için anahtar
  final _key = encrypt.Key.fromLength(32);

  SharedPrefsProvider() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _iv = encrypt.IV.fromLength(16);
  }

  Future<SharedPreferences> get sharedPreferences async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  // Veriyi şifrele
  String _encrypt(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  // Şifrelenmiş veriyi çöz
  String _decrypt(String encryptedData) {
    return _encrypter.decrypt64(encryptedData, iv: _iv);
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

    firebaseProvider.firstRunDate = prefs.getString(firstRunDateKey) as DateTime?;
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
    firebaseProvider.weeklyAmount = amt as double;
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

  // Hassas bilgileri şifreleyerek kaydet
  Future<void> saveEmailAndPassword(String email, String password) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setString(emailKey, _encrypt(email));
    await prefs.setString(passwordKey, _encrypt(password));
  }

  // Hassas bilgileri şifreleyerek kaydet
  Future<void> saveGmailAndPassword(String email, String password) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setString(gmailKey, _encrypt(email));
    await prefs.setString(gmailPasswordKey, _encrypt(password));
  }

  Future<void> setSignInMethod(SignInMethod signInMethod) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setInt(signInMethodKey, signInMethod.index);
  }

  Future<SignInMethod> getSignInMethod() async {
    final SharedPreferences prefs = await sharedPreferences;
    final int? value = prefs.getInt(signInMethodKey);
    return value == null ? SignInMethod.none : SignInMethod.values[value];
  }

  // Hassas bilgileri çözerek al
  Future<String?> getString(String key) async {
    final SharedPreferences prefs = await sharedPreferences;
    final String? encryptedValue = prefs.getString(key);
    if (encryptedValue == null) return null;
    return _decrypt(encryptedValue);
  }

  // Hassas bilgileri şifreleyerek kaydet
  Future<void> setString(String key, String value) async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.setString(key, _encrypt(value));
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.remove(credentialKey);
  }

  // Hassas bilgileri güvenli bir şekilde sil
  Future<void> clearSensitiveData() async {
    final SharedPreferences prefs = await sharedPreferences;
    await prefs.remove(emailKey);
    await prefs.remove(passwordKey);
    await prefs.remove(gmailKey);
    await prefs.remove(gmailPasswordKey);
  }
}

final sharedPrefsProvider = SharedPrefsProvider();
