import 'package:flutter/material.dart';
import '../Context/Profiles/ProfileContext.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: profileContent(context),
    );
  }
}
