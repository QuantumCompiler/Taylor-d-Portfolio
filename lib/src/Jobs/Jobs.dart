import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'LoadJob.dart';
import 'NewJob.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          jobsTitle,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * jobTileContainerWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              ListTile(
                title: Text(
                  jobsCreateNew,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NewJobPage()));
                },
              ),
              ListTile(
                title: Text(
                  jobsLoad,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoadJobPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
