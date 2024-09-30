// Imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taylord_portfolio/src/Context/Globals/GlobalContext.dart';
import '../Themes/Themes.dart';
import '../Context/Settings/SettingsContext.dart';

class SettingsPage extends StatefulWidget {
  final String? version;

  SettingsPage({
    Key? key,
    this.version,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? version;

  @override
  void initState() {
    super.initState();
    _getVersionInfo();
    version = widget.version ?? '1.0.0';
  }

  Future<void> _getVersionInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      setState(() {
        version = info.version;
      });
    } catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: appBar(context),
      body: bodyContent(context, theme, version),
      bottomNavigationBar: BottomNav(context),
    );
  }
}
