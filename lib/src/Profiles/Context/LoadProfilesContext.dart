import 'package:flutter/material.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Edit/EditProfile.dart';
import '../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';

/* appBar - AppBar for the load profile page
      Input:
        context: BuildContext of the page
        profiles: List of profiles
        state: Function to update the state of the page
      Algorithm:
          * Create a back button to return to the previous page
          * Modify the navigation based on the device type
          * Add a title to the AppBar
      Output:
        Returns an AppBar
*/
AppBar appBar(BuildContext context, final profiles, Function state) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
        state(() {});
      },
    ),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.dashboard),
        onPressed: () {
          if (isDesktop()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else if (isMobile()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
    title: Text(
      profiles.isEmpty ? profilesEmptyTitle : loadProfilesTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  loadingProfilesAppBar - AppBar for the loading profiles page
      Input:
        context: BuildContext of the page
      Algorithm:
          * Create a back button to return to the previous page
          * Add a title to the AppBar
      Output:
        Returns an AppBar
*/
AppBar loadingProfilesAppBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      currentlyLoadingProfiles,
    ),
  );
}

/*  loadingProfilesContent - Body content for the loading profiles page
      Input:
        None
      Algorithm:
          * Display a CircularProgressIndicator
      Output:
        Returns a Center widget with a CircularProgressIndicator
*/
Center loadingProfilesContent() {
  return const Center(child: CircularProgressIndicator());
}

/* loadProfileContent - Body content for the load profile page
      Input:
        context: BuildContext of the page
        profiles: List of profiles
        state: Function to update the state of the page
      Algorithm:
          * Create a container to hold the profile tiles
          * Populate the container with a ListView of profile tiles
      Output:
        Returns a Center widget with a container of profile tiles
*/
Center loadProfileContent(BuildContext context, final profiles, Function state) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * profileTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          Expanded(
            child: ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ListTile(
                    title: Text(profiles[index].path.split('/').last),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                "$deleteButton ${profiles[index].path.split('/').last}?",
                                style: TextStyle(
                                  fontSize: appBarTitle,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                deleteProfilePrompt,
                                style: TextStyle(
                                  fontSize: secondaryTitles,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              actions: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      child: Text(cancelButton),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    SizedBox(width: standardSizedBoxWidth),
                                    ElevatedButton(
                                      child: Text(deleteButton),
                                      onPressed: () async {
                                        await DeleteProfile(profiles[index].path.split('/').last);
                                        Navigator.of(context).pop();
                                        state(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(profileName: profiles[index].path.split('/').last),
                        ),
                      ).then(
                        (_) {
                          state(() {});
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
