import 'package:flutter/material.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/EditProfile.dart';
import '../../Profiles/NewProfile.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar ProfileAppBar(BuildContext context, List<Profile> profiles) {
  return AppBar(
    title: Text(
      profiles.isNotEmpty ? 'Profiles, Edit Or Create New' : 'Profiles, Create New Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
      },
    ),
    actions: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    ],
  );
}

SingleChildScrollView ProfileContent(BuildContext context, List<Profile> profiles, Function setState) {
  return SingleChildScrollView(
    child: profiles.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Text(
                  'View / Edit Previous Profiles',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * titleContainerWidth,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To Edit ${profiles[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(profiles[index].name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Delete Profile ${profiles[index].name}',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 30.0,
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Delete Profile ${profiles[index].name}?',
                                                  style: TextStyle(
                                                    fontSize: appBarTitle,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Icon(
                                                  Icons.warning,
                                                  size: 50.0,
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Text(
                                                  'Are you sure that you would like to delete this profile?\nThis cannot be undone.',
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      child: Text(
                                                        'Cancel',
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    SizedBox(width: standardSizedBoxWidth),
                                                    ElevatedButton(
                                                      child: Text('Delete'),
                                                      onPressed: () async {
                                                        try {
                                                          await DeleteProfile(profiles[index].name);
                                                          setState(
                                                            () {
                                                              profiles.removeAt(index);
                                                            },
                                                          );
                                                          Navigator.of(context).pop();
                                                        } catch (e) {
                                                          throw ('Error in deleting ${profiles[index].name}');
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: EditProfilePage(profileName: profiles[index].name)), (Route<dynamic> route) => false);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage()), (Route<dynamic> route) => false);
                  },
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'No Current Profiles',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: Tooltip(
                  message: 'Create A New Profile',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          ),
  );
}
