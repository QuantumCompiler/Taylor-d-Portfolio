import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/EditProfile.dart';
import '../../Utilities/GlobalUtils.dart';

Widget LoadProfileContent(BuildContext context, dynamic profiles, Function setState) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * titleContainerWidth,
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          return Tooltip(
            message: 'Click To Edit ${profiles[index].name}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GenListTileWithDelFunc(
                context,
                '${profiles[index].name}',
                profiles[index],
                () => GenAlertDialogWithFunctions(
                  'Delete ${profiles[index].name}?',
                  'Do you want to delete ${profiles[index].name}?\n This cannot be undone.',
                  'Cancel',
                  'Delete',
                  () => {},
                  () async {
                    await DeleteProfile('${profiles[index].name}');
                    setState(() {
                      profiles.removeAt(index);
                    });
                    Navigator.pop(context);
                  },
                  setState,
                ),
                (context, profile) async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(profileName: profiles[index].name),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                setState,
              ),
            ),
          );
        },
      ),
    ),
  );
}