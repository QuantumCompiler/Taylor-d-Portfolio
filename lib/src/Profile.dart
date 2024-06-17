import 'package:flutter/material.dart';
import 'package:taylord_resume/src/Dashboard.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
        child: Column(
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     // Code to load profile or edit profile
            //   },
            //   child: Text('Load Profile / Edit Profile'),
            // ),
            // SizedBox(height: 16.0),
            // ElevatedButton(
            //   onPressed: () {
            //     // Code to create a new profile
            //   },
            //   child: Text('New Profile'),
            // ),
            LoadProfileCard(),
            NewProfileCard(),
          ],
        ),
      ),
    );
  }
}

class LoadProfileCard extends StatelessWidget {
  const LoadProfileCard({super.key});
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
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 0, 213, 255),
                    ),
                    child: Text(
                      'Load',
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

class NewProfileCard extends StatelessWidget {
  const NewProfileCard({super.key});
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
                    onPressed: () {},
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


      // body: Padding(
      //   padding: EdgeInsets.all(16.0),
      //   child: Column(
      //     children: [
      //       TextField(
      //         decoration: InputDecoration(
      //           labelText: 'Name',
      //         ),
      //       ),
      //       SizedBox(height: 16.0),
      //       TextField(
      //         decoration: InputDecoration(
      //           labelText: 'Email',
      //         ),
      //       ),
      //       SizedBox(height: 16.0),
      //       TextField(
      //         decoration: InputDecoration(
      //           labelText: 'Phone',
      //         ),
      //       ),
      //       SizedBox(height: 16.0),
      //       ElevatedButton(
      //         onPressed: () {},
      //         child: Text('Submit'),
      //       ),
      //     ],
      //   ),
      // ),
