import 'package:flutter/material.dart';
import '../Globals/ProfileGlobals.dart';
import '../Load/LoadProfile.dart';
import '../New/NewProfile.dart';
import '../../Globals/Globals.dart';

/*  appBar - AppBar for the profile page
      Constructor:
        Input:
          context: BuildContext
        Algorithm:
            * Return AppBar with title and back button
      Output:
          Returns an AppBar
*/
AppBar appBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        if (isDesktop()) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else if (isMobile()) {
          Navigator.of(context).pop();
        }
      },
    ),
    title: Text(
      profileTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  profileContent - Body content for the profile page
      Input:
        context: BuildContext
      Algorithm:
          * Return a center widget with a container for the profile
          * Populate the container with a column of profile options
      Output:
          Returns a Center widget with a container for the profile
*/
Center profileContent(BuildContext context) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * profileTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          ListTile(
            title: Text(
              createNewProfilePrompt,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NewProfilePage()));
            },
          ),
          ListTile(
            title: Text(
              loadProfilesTitle,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoadProfilePage()));
            },
          ),
        ],
      ),
    ),
  );
}
