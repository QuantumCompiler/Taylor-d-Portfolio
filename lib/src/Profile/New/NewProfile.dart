import 'package:flutter/material.dart';
import 'Context/NewProfileContext.dart';
import '../Utilities/ProfileUtils.dart';

class NewProfilePage extends StatelessWidget {
  const NewProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    Profile newProfile = Profile();
    return Scaffold(
      appBar: appBar(context),
      body: newProfileContent(context, newProfile),
      bottomNavigationBar: bottomAppBar(context, newProfile),
    );
  }
}
