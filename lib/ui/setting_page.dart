import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
import '../resource/firebase_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int selectedRadioValue;
  final FirebaseProvider firebaseProvider = FirebaseProvider();

  @override
  void initState() {
    super.initState();
    selectedRadioValue = (firebaseProvider.weeklyAmount).toInt();
  }

  Future<void> handleRestore() async {
    try {
      await firebaseProvider.checkInternetConnection();
      List<Routine> routines = await firebaseProvider.restoreRoutines();
      if (routines.isNotEmpty) {
        routinesBloc.restoreRoutines();
        showMsg("Restored Successfully");
      } else {
        showMsg("No Data Found");
      }
    } catch (e) {
      showMsg("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text("Back up my data"),
              onTap: onBackUpTapped,
            ),
            const Padding(padding: EdgeInsets.only(left: 56), child: Divider(height: 0)),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text("Restore my data"),
              onTap: handleRestore,
            ),
            const Padding(padding: EdgeInsets.only(left: 56), child: Divider(height: 0)),
            AboutListTile(
              applicationIcon: SizedBox(
                height: 50,
                width: 50,
                child: Image.asset('assets/app_icon.png', fit: BoxFit.contain),
              ),
              applicationVersion: 'v1.1.6',
              aboutBoxChildren: [
                ElevatedButton(
                  onPressed: () {
                    launchUrl(Uri.parse("https://livinglist.github.io"));
                  },
                  child: const Row(
                    children: [
                      Icon(FontAwesomeIcons.addressCard),
                      SizedBox(width: 12),
                      Text("Developed by adeveli"),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    launchUrl(Uri.parse("https://github.com/adeveli101"));
                  },
                  child: const Row(
                    children: [
                      Icon(FontAwesomeIcons.github),
                      SizedBox(width: 12),
                      Text("Github"),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.info),
            ),
          ],
        ),
      ),
    );
  }

  void showMsg(String msg) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(msg),
          actions: [
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void onBackUpTapped() async {
    try {
      await firebaseProvider.checkInternetConnection();
      await uploadRoutines();
      if (!mounted) return;
      showMsg('Data uploaded');
    } catch (e) {
      showMsg('Error uploading data');
    }
  }

  Future<void> uploadRoutines() async {
    try {
      var routines = await routinesBloc.allRoutines.first;
      if (kDebugMode) print("uploading");
      await firebaseProvider.uploadRoutines(routines);
    } catch (e) {
      showMsg('Error uploading routines');
    }
  }
}
