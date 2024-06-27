import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'dart:io';
import 'EditJob.dart';
import 'JobsUtils.dart';

class LoadJobPage extends StatefulWidget {
  const LoadJobPage({super.key});

  @override
  LoadJobPageState createState() => LoadJobPageState();
}

class LoadJobPageState extends State<LoadJobPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>>(
      future: RetrieveSortedJobs(),
      builder: (BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final jobs = snapshot.data ?? [];
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {});
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
                jobs.isEmpty ? 'No Jobs' : 'Load Jobs',
                style: TextStyle(
                  fontSize: appBarTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: jobs.isEmpty
                ? Container()
                : Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * jobTileContainerWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: standardSizedBoxHeight),
                          Expanded(
                            child: ListView.builder(
                              itemCount: jobs.length,
                              itemBuilder: (context, index) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: ListTile(
                                    title: Text(jobs[index].path.split('/').last),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Delete ${jobs[index].path.split('/').last}?",
                                                style: TextStyle(
                                                  fontSize: appBarTitle,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete this job?",
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
                                                      child: Text("Cancel"),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    SizedBox(width: standardSizedBoxWidth),
                                                    ElevatedButton(
                                                      child: Text("Delete"),
                                                      onPressed: () {
                                                        DeleteJob(jobs[index].path.split('/').last);
                                                        Navigator.of(context).pop();
                                                        setState(() {});
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
                                          builder: (context) => EditJobPage(jobName: jobs[index].path.split('/').last),
                                        ),
                                      ).then(
                                        (_) {
                                          setState(() {});
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
                  ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Loading Jobs...'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
