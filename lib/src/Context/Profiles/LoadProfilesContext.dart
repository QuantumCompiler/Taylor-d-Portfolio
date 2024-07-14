import 'package:flutter/material.dart';
import '../../Context/Globals/GlobalContexts.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Profiles/EditProfile.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Globals/Globals.dart';

Center LoadProfileContent(BuildContext context, final profiles, Function state) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * titleContainerWidth,
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          return Tooltip(
            message: 'Click To Edit - ${profiles[index].name}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GenListTileWithDelFunc(
                context,
                '${profiles[index].name}',
                profiles[index],
                () => GenAlertDialogWithFunctions(
                  '$deleteButton ${profiles[index].name}?',
                  deleteProfilePrompt,
                  cancelButton,
                  deleteButton,
                  () => Navigator.of(context).pop(),
                  () async => await DeleteProfile('${profiles[index].name}'),
                  state,
                ),
                (context, profile) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(profileName: '${profile.name}'),
                    ),
                  );
                },
                state,
              ),
            ),
          );
        },
      ),
    ),
  );
}
