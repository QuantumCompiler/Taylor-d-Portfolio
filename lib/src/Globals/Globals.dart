import 'dart:io';
import 'package:flutter/material.dart';
import 'ApplicationsGlobals.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Booleans
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Is Desktop
bool isDesktop() {
  return (Platform.isMacOS || Platform.isLinux || Platform.isWindows);
}

// Is Mobile
bool isMobile() {
  return (Platform.isIOS || Platform.isAndroid);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Button Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double buttonTitle = 16;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Colors
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
Color customCyan = Color.fromARGB(255, 0, 213, 255);
Color whiteButtonColor = Colors.white;
Color blackTextColor = Colors.black;
Color whiteTextColor = Colors.white;
Color cardHoverColor = Color.fromARGB(255, 0, 255, 60);

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Directories
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Directory Names
String applicationsMasterDir = 'Applications';
String jobsMasterDir = 'Jobs';
String latexMasterDir = 'LaTeX';
String profilesMasterDir = 'Profiles';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Size Box Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double standardSizedBoxHeight = 20;
double standardSizedBoxWidth = 20;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Text Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double appBarTitle = 24.0;
double secondaryTitles = 16.0;

double titleContainerWidth = 0.6;
double containerWidth = 0.8;

enum ProfileContentType {
  coverLetter,
  education,
  experience,
  projects,
  skills,
}

enum JobContentType {
  description,
  other,
  role,
  skills,
}

final openAIEntries = [
  DropdownMenuEntry(
    value: gpt_4o_2024_05_13,
    label: 'GPT-4o 5/13/2024',
    trailingIcon: Icon(Icons.recommend),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.green),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4o,
    label: 'GPT-4o',
    trailingIcon: Icon(Icons.recommend),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.green),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_turbo_turbo_preview,
    label: 'GPT-4 Turbo Turbo Preview',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_turbo_2024_04_09,
    label: 'GPT-4 Turbo 4/9/2024',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_turbo,
    label: 'GPT-4 Turbo',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_1106_preview,
    label: 'GPT-4 1106 Preview',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_0613,
    label: 'GPT-4 0613',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4_0125_preview,
    label: 'GPT-4 0125 Preview',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_4,
    label: 'GPT-4',
    trailingIcon: Icon(Icons.warning),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.amber),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_3_5_turbo_16k,
    label: 'GPT-3.5 Turbo 16k',
    trailingIcon: Icon(Icons.fmd_bad_rounded),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.red),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_3_5_turbo_1106,
    label: 'GPT-3.5 Turbo 1106',
    trailingIcon: Icon(Icons.fmd_bad_rounded),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.red),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_3_5_turbo_0125,
    label: 'GPT-3.5 Turbo 0125',
    trailingIcon: Icon(Icons.fmd_bad_rounded),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.red),
    ),
  ),
  DropdownMenuEntry(
    value: gpt_3_5_turbo,
    label: 'GPT-3.5 Turbo',
    trailingIcon: Icon(Icons.fmd_bad_rounded),
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all<Color>(Colors.red),
    ),
  ),
];
