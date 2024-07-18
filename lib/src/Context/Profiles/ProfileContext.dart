import 'package:flutter/material.dart';
import 'package:taylord_portfolio/src/Globals/Globals.dart';
import 'package:taylord_portfolio/src/Profiles/LoadProfiles.dart';
import 'package:taylord_portfolio/src/Utilities/GlobalUtils.dart';
// import '../Globals/GlobalContext.dart';
// import '../../Globals/Globals.dart';
// import '../../Globals/ProfilesGlobals.dart';
// import '../../Profiles/LoadProfiles.dart';
// import '../../Profiles/NewProfile.dart';
import '../../Utilities/ProfilesUtils.dart';

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
                                      await DeleteProfile(profiles[index].name);
                                      setState(
                                        () {
                                          profiles.removeAt(index);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => {},
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
                    setState(() {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoadProfilePage()));
                    });
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
            ],
          ),
  );
}
// This Works!
// setState(() {
//   profiles[1].setProfName('55');
// });