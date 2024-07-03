import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Jobs/EditJob.dart';
import '../Utilities/JobUtils.dart';
import '../Globals/Globals.dart';
import '../Utilities/ProfilesUtils.dart';
import '../Profiles/EditProfile.dart';
import '../Themes/Themes.dart';

AppBar appBar(BuildContext context, Function state) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
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
      newApplicationTitle,
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView loadApplicationContent(BuildContext context, ApplicationContent content, Function state) {
  return SingleChildScrollView(
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * applicationsContainerWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: standardSizedBoxHeight),
            Text(
              'Choose A Job To Apply To',
              style: TextStyle(
                color: themeTextColor(context),
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Container(
              width: MediaQuery.of(context).size.width * applicationsContainerWidth,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: content.jobs.length,
                itemBuilder: (context, index) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Tooltip(
                        message: 'Click To Edit ${content.jobs[index].path.split('/').last}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(content.jobs[index].path.split('/').last),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Select ${content.jobs[index].path.split('/').last}',
                                  child: Checkbox(
                                    value: content.checkedJobs.contains(content.jobs[index].path.split('/').last),
                                    onChanged: (bool? value) {
                                      content.updateBoxes(content.checkedJobs, content.jobs[index].path.split('/').last, value, setState);
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Delete ${content.jobs[index].path.split('/').last}',
                                  child: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      await DeleteJob(content.jobs[index].path.split('/').last);
                                      state(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditJobPage(jobName: content.jobs[index].path.split('/').last),
                                ),
                              ).then(
                                (_) {
                                  state(() {});
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Text(
              'Choose A Profile To Apply With',
              style: TextStyle(
                color: themeTextColor(context),
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Container(
              width: MediaQuery.of(context).size.width * applicationsContainerWidth,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: content.profiles.length,
                itemBuilder: (context, index) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Tooltip(
                        message: 'Click To Edit ${content.profiles[index].path.split('/').last}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(content.profiles[index].path.split('/').last),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Select ${content.profiles[index].path.split('/').last}',
                                  child: Checkbox(
                                    value: content.checkedProfiles.contains(content.profiles[index].path.split('/').last),
                                    onChanged: (bool? value) {
                                      content.updateBoxes(content.checkedProfiles, content.profiles[index].path.split('/').last, value, setState);
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Delete ${content.profiles[index].path.split('/').last}',
                                  child: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      await DeleteProfile(content.profiles[index].path.split('/').last);
                                      state(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfilePage(profileName: content.profiles[index].path.split('/').last),
                                ),
                              ).then(
                                (_) {
                                  state(() {});
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

BottomAppBar bottomAppBar(BuildContext context, ApplicationContent content, Function state) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            content.clearBoxes(content.checkedJobs, content.checkedProfiles, state);
          },
          child: Text(
            'Clear',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () async {
            bool valid = content.verifyBoxes();
            if (valid) {
              List<String> names = content.getContent();
              List<List<String>> appContent = await prepContent(names);
              // try {
              //   OpenAI testPrompt = OpenAI(
              //     apikey: dotenv.env[apiKey]!,
              //     openAIModel: gpt_4o,
              //     systemRole: '''You are interpreting information from a job posting and a resume and giving recommendations for what the applicant should put on their main resume.
              //                 \n When interpreting the resume and comparing it to the job posting
              //                 \n - Give the two schools, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give the three jobs, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give 10 mathematical skills, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give 10 personal skills, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give the framework(s), that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give 20 the programming skills, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give 10 the scientific skills, that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 \n - Give 3, that the applicant should put on their resume, and refer to them by name. that the applicant should put on their resume. Format your recommendation in a list surrounded by brackets like this [].
              //                 ''',
              //     userPrompt: '''Interpret the information first from the job posting:
              //               \nJob Description: ${appContent[0][0]}
              //               \nOther Info: ${appContent[0][1]}
              //               \nPosition Info: ${appContent[0][2]}
              //               \nQualifications / Skills Requirements: ${appContent[0][3]}
              //               \nRole Information: ${appContent[0][4]}
              //               \nTask Information: ${appContent[0][5]}
              //               \nNow, interpret the applicants resume:
              //               \nEducation: ${appContent[1][0]}
              //               \nExperience: ${appContent[1][1]}
              //               \nExtracurricular: ${appContent[1][2]}
              //               \nHonors: ${appContent[1][3]}
              //               \nProjects: ${appContent[1][4]}
              //               \nSkills: ${appContent[1][6]}
              //               ''',
              //     maxTokens: 1000,
              //   );
              //   final test = await testPrompt.testPrompt();
              //   print(test);
              // } catch (e) {
              //   print('Error: $e');
              // }
            }
          },
          child: Text(
            'Generate Application',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
