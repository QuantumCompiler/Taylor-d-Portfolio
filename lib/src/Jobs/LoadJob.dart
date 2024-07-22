// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../Context/Jobs/LoadJobContext.dart';
// import '../Utilities/JobUtils.dart';

// class LoadJobPage extends StatefulWidget {
//   const LoadJobPage({super.key});

//   @override
//   LoadJobPageState createState() => LoadJobPageState();
// }

// class LoadJobPageState extends State<LoadJobPage> {
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Directory>>(
//       future: RetrieveSortedJobs(),
//       builder: (BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           final jobs = snapshot.data ?? [];
//           return Scaffold(
//             appBar: appBar(context, jobs, setState),
//             body: jobs.isEmpty ? Container() : loadJobsContent(context, jobs, setState),
//           );
//         } else {
//           return Scaffold(
//             appBar: loadingJobsAppBar(context),
//             body: loadingJobsContent(),
//           );
//         }
//       },
//     );
//   }
// }
