import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'LoadProfile.dart';
import 'NewProfile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          profileTitle,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * profileTileContainerWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              ListTile(
                title: Text(
                  profileCreateNew,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NewProfilePage()));
                },
              ),
              ListTile(
                title: Text(
                  profileLoad,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoadProfilePage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
