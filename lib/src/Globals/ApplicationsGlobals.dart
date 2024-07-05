// Sizes
double applicationsTileContainerWidth = 0.6;
double applicationsTitleSize = 24.0;
double applicationsContainerWidth = 0.8;

// Titles & Hints
String applicationsTitle = 'Applications';
String createNewApplicationTile = 'Create New Application';
String newApplicationTitle = 'New Application';

// API Key
String apiKey = 'OPENAI_API_KEY';

// OpenAI Models
String gpt_3_5_personal = 'ft:gpt-3.5-turbo-1106:personal::9hSa098j';
String gpt_3_5_turbo = 'gpt-3.5-turbo';
String gpt_3_5_turbo_0125 = 'gpt-3.5-turbo-0125';
String gpt_3_5_turbo_1106 = 'gpt-3.5-turbo-1106';
String gpt_3_5_turbo_16k = 'gpt-3.5-turbo-16k';
String gpt_4 = 'gpt-4';
String gpt_4_0125_preview = 'gpt-4-0125-preview';
String gpt_4_0613 = 'gpt-4-0613';
String gpt_4_1106_preview = 'gpt-4-1106-preview';
String gpt_4_turbo = 'gpt-4-turbo';
String gpt_4_turbo_2024_04_09 = 'gpt-4-turbo-2024-04-09';
String gpt_4_turbo_turbo_preview = 'gpt-4-turbo-preview';
String gpt_4o = 'gpt-4o';
String gpt_4o_2024_05_13 = 'gpt-4o-2024-05-13';

String hiringManagerRole = '''
You are an assistant that is helping extract structured information from a job posting and portfolio. 
You are to give recommendations to an applicant that will most likely help them get an interview for a position.
You are going to achieve this by comparing the job content to the applicant's portfolio and then providing recommendations.
''';

String jobContentPrompt = '''Extract the following information from the job content, just digest it for now:''';

String profContentPrompt = '''Extract the following information from the user's portfolio, just digest it for now:''';

String returnPrompt = '''
Return the recommendations in the following JSON Format. 
Ensure each field contains only the recommended names or items as specified, without any additional text or explanations. Capitalize every new word. Keep each recommendation short and concise (one to four words):
{
    "Education_Recommendations": ["School Name 1", "School Name 2"],
    "Experience_Recommendations": ["Workplace 1", "Workplace 2", "Workplace 3"],
    "Projects_Recommendations": ["Project 1", "Project 2", "Project 3"],
    "Math_Skills_Recommendations": ["Math Skill 1", "Math Skill 2", "Math Skill 3", "Math Skill 4", "Math Skill 5", "Math Skill 6", "Math Skill 7", "Math Skill 8", "Math Skill 9", "Math Skill 10", "Math Skill 11", "Math Skill 12", "Math Skill 13", "Math Skill 14", "Math Skill 15"],
    "Personal_Skills_Recommendations": ["Personal Skill 1", "Personal Skill 2", "Personal Skill 3", "Personal Skill 4", "Personal Skill 5", "Personal Skill 6", "Personal Skill 7", "Personal Skill 8", "Personal Skill 9", "Personal Skill 10", "Personal Skill 11", "Personal Skill 12", "Personal Skill 13", "Personal Skill 14", "Personal Skill 15"],
    "Framework_Recommendations": ["Framework 1", "Framework 2", "Framework 3", "Framework 4", "Framework 5", "Framework 6", "Framework 7", "Framework 8", "Framework 9", "Framework 10"],
    "Programming_Languages_Recommendations": ["Programming Language 1", "Programming Language 2", "Programming Language 3", "Programming Language 4", "Programming Language 5", "Programming Language 6", "Programming Language 7", "Programming Language 8", "Programming Language 9", "Programming Language 10"],
    "Programming_Skills_Recommendations": ["Programming Skill 1", "Programming Skill 2", "Programming Skill 3", "Programming Skill 4", "Programming Skill 5", "Programming Skill 6", "Programming Skill 7", "Programming Skill 8", "Programming Skill 9", "Programming Skill 10", "Programming Skill 11", "Programming Skill 12", "Programming Skill 13", "Programming Skill 14", "Programming Skill 15"],
    "Scientific_Skills_Recommendations": ["Scientific Skill 1", "Scientific Skill 2", "Scientific Skill 3", "Scientific Skill 4", "Scientific Skill 5", "Scientific Skill 6", "Scientific Skill 7", "Scientific Skill 8", "Scientific Skill 9", "Scientific Skill 10", "Scientific Skill 11", "Scientific Skill 12", "Scientific Skill 13", "Scientific Skill 14", "Scientific Skill 15"]
}
Make sure the response is a valid JSON object and nothing else. Only include the names of the schools, workplaces, and projects that you recommend. For experience and projects, strictly provide exactly 3 and 3 items respectively. For skills, frameworks, and languages, provide up to 15 items each if available, otherwise list only what is present in the portfolio.
''';

final Map<String, dynamic> testOpenAIResults = {
  "Education_Recommendations": ["The University Of Colorado At Boulder", "Colorado Mesa University"],
  "Experience_Recommendations": ["Applied Materials", "University Of Oklahoma", "Mesa Lavender Farms"],
  "Projects_Recommendations": ["Celestial Bodies In Space", "Formulator Pro", "RSA"],
  "Math_Skills_Recommendations": [
    "Computational Mathematics",
    "Differential Equations",
    "Fourier Analysis",
    "Linear Algebra",
    "Mathematical Modeling",
    "Multivariate Calculus",
    "Numerical Analysis",
    "Probability Theory",
    "Statistics",
    "Tensor Analysis"
  ],
  "Personal_Skills_Recommendations": [
    "Adaptability",
    "Attention To Detail",
    "Communication",
    "Conflict Resolution",
    "Critical Thinking",
    "Decision Making",
    "Leadership",
    "Multitasking",
    "Organization",
    "Presentation Skills",
    "Problem Solving",
    "Project Management",
    "Research Skills",
    "Resourcefulness",
    "Time Management"
  ],
  "Framework_Recommendations": ["ElectronJS", "Flutter", "Qt"],
  "Programming_Languages_Recommendations": ["Python", "C/C++", "JavaScript", "Java", "Dart", "Assembly (x86)", "HTML", "CSS", "LATEX"],
  "Programming_Skills_Recommendations": [
    "Algorithms & Data Structures",
    "Desktop & Mobile App Development",
    "Documentation",
    "Dynamic Programming",
    "OOP Design",
    "Quality Assurance",
    "Scientific Programming",
    "Software Design",
    "Systems Level Development",
    "Testing & Debugging",
    "Unit Testing",
    "Version Control",
    "Web Development"
  ],
  "Scientific_Skills_Recommendations": [
    "Computational Problem Solving",
    "Data Analysis & Visualization",
    "Error Analysis",
    "Experimental Design",
    "Laboratory Techniques",
    "Literature Review",
    "Plotting",
    "Precision Measurement",
    "Risk Assessment",
    "Scientific Communication",
    "Statistical Analysis",
    "Technical Writing"
  ]
};
