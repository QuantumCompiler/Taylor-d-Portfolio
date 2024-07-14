import 'package:flutter/material.dart';
import '../../Context/Globals/GlobalContexts.dart';
import '../../Globals/Globals.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Profiles/LoadProfiles.dart';
import '../../Profiles/NewProfile.dart';

Center ProfileContent(BuildContext context) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * profileTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          GenListTileWithRoute(context, createNewProfilePrompt, NewProfilePage()),
          GenListTileWithRoute(context, loadProfilesTitle, LoadProfilePage()),
        ],
      ),
    ),
  );
}
