import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'Türkçe';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Bildirimler'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text('Karanlık Mod'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text('Dil'),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
              items: <String>['Türkçe', 'English', 'Español', 'Français', 'Deutsch', 'Italiano', 'Português', 'Русский', '中文', '日本語']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Hesap Ayarları'),
            onTap: () {
              // Hesap ayarları sayfasına yönlendir
            },
          ),
          ListTile(
            title: Text('Yardım'),
            onTap: () {
              // Yardım sayfasına yönlendir
            },
          ),
          ListTile(
            title: Text('Hakkında'),
            onTap: () {
              // Hakkında sayfasına yönlendir
            },
          ),
          Divider(),

        ],
      ),
    );
  }
}