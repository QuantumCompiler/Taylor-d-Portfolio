import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool showNewProfile = false;
  bool showProfileList = false;
  @override
  Widget build(BuildContext context) {
    if (showProfileList) {
      // return LoadProfiles(setState, () => showProfileList = false);
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
          child: LoadProfiles(setState, () => showProfileList = false),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
          child: showNewProfile ? NewProfileForm(setState, () => showNewProfile = false) : BuildProfileCards(),
        ),
      );
    }
  }

  Widget BuildProfileCards() {
    return Column(
      children: [
        LoadProfileCard(
          key: UniqueKey(),
          onLoadProfile: () {
            setState(() {
              showProfileList = true;
            });
          },
        ),
        NewProfileCard(
          key: UniqueKey(),
          onCreateNewProfile: () {
            setState(() {
              showNewProfile = true;
            });
          },
        ),
      ],
    );
  }
}

class LoadProfileCard extends StatelessWidget {
  final VoidCallback onLoadProfile;
  const LoadProfileCard({required Key key, required this.onLoadProfile}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'Load Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onLoadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 0, 213, 255),
                    ),
                    child: Text(
                      'Load Previous Profiles',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget LoadProfiles(Function state, Function toggleShow) {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Center(
          child: Text('Load Recent Profiles'),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () {
              state(() {
                toggleShow();
              });
            },
            child: Text('Cancel'),
          ),
        ),
      ],
    ),
  );
}

class NewProfileCard extends StatelessWidget {
  final VoidCallback onCreateNewProfile;
  const NewProfileCard({required Key key, required this.onCreateNewProfile}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'New Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onCreateNewProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 0, 213, 255),
                    ),
                    child: Text(
                      'Create New Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget NewProfileForm(Function state, Function toggleShow) {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Center(
          child: Text('Form goes here'),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () {
              state(() {
                toggleShow();
              });
            },
            child: Text('Cancel'),
          ),
        ),
      ],
    ),
  );
}
