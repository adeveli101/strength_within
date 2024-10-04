import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sign_button/sign_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workout/bloc/routines_bloc.dart';
import 'package:workout/resource/firebase_provider.dart';
import 'package:workout/resource/shared_prefs_provider.dart';
import '../models/routine.dart';

class SettingPage extends StatefulWidget {
  final VoidCallback signInCallback;
  const SettingPage({super.key, required this.signInCallback});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late int selectedRadioValue;

  Future<void> handleRestore() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none) && connectivityResults.length == 1) {
      showMsg("No Internet Connection");
    } else {
      if (await firebaseProvider.checkUserExists()) {
        routinesBloc.restoreRoutines();
      } else {
        showMsg("No Data Found");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedRadioValue = firebaseProvider.weeklyAmount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: StreamBuilder<List<Routine>>(
          stream: routinesBloc.allRecRoutines,
          builder: (_, AsyncSnapshot<List<Routine>> snapshot) {
            return StreamBuilder<User?>(
              stream: firebaseProvider.firebaseAuth.authStateChanges(),
              builder: (_, sp) {
                var firebaseUser = sp.data;
                if (firebaseUser != null) firebaseProvider.firebaseUser = firebaseUser;

                return ListView(
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
                      onTap: () {
                        if (firebaseUser == null) {
                          showMsg("You should sign in first");
                          return;
                        }
                        handleRestore().whenComplete(() => showMsg("Restored Successfully"));
                      },
                    ),
                    const Padding(padding: EdgeInsets.only(left: 56), child: Divider(height: 0)),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(firebaseUser == null ? 'Sign In' : 'Sign out'),
                      subtitle: firebaseUser == null ? null : Text(firebaseUser.displayName ?? ""),
                      onTap: () {
                        if (firebaseUser == null) {
                          showSignInModalSheet();
                        } else {
                          signOut();
                        }
                      },
                    ),
                    const Padding(padding: EdgeInsets.only(left: 56), child: Divider(height: 0)),

                    AboutListTile(
                      applicationIcon: SizedBox(
                        height: 50,
                        width: 50,
                        child: Image.asset(
                          'assets/app_icon.png',
                          fit: BoxFit.contain,
                        ),
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
                );
              },
            );
          },
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
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showMsg("No Internet Connection");
      return;
    }
    await uploadRoutines();
    if (!mounted) return;
    showMsg('Data uploaded');
  }



  Future<void> uploadRoutines() async {
    if (!mounted) return;
    var connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.isEmpty || connectivityResults.every((result) => result == ConnectivityResult.none)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No Internet Connection'),
        action: SnackBarAction(
          label: 'Okay',
          onPressed: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ));
    } else {
      var routines = await routinesBloc.allRoutines.first;
      if (kDebugMode) {
        print("uploading");
      }
      await firebaseProvider.uploadRoutines(routines);
    }
  }

  void signInAndRestore(ButtonType buttonType) {
    if (buttonType == ButtonType.apple) {
      firebaseProvider.signInApple().then((firebaseUser) {
        firebaseProvider.checkUserExists().then((userExists) {
          if (userExists) showRestoreDialog();
        });
      });
    } else if (buttonType == ButtonType.google) {
      firebaseProvider.signInGoogle().then((firebaseUser) {
        firebaseProvider.checkUserExists().then((userExists) {
          if (userExists) showRestoreDialog();
        });
      });
    }
  }

  void showRestoreDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Restore your data?'),
          content: const Text('Looks like you have your data on the cloud, do you want to restore them to this device?'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                routinesBloc.restoreRoutines();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void signOut() {
    firebaseProvider.signOut();
    sharedPrefsProvider.signOut();
  }

  void showSignInModalSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 200,
          child: Column(
            children: [
              SignInButton(
                buttonType: ButtonType.google,
                onPressed: () {
                  Navigator.pop(context, ButtonType.google);
                },
              ),
              const SizedBox(height: 12),
              SignInButton(
                buttonType: ButtonType.apple,
                onPressed: () {
                  Navigator.pop(context, ButtonType.apple);
                },
              ),
            ],
          ),
        );
      },
    ).then((val) {
      if (val != null) signInAndRestore(val);
    });
  }
}
