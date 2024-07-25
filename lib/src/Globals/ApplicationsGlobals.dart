// Sizes
double applicationsContainerWidth = 0.8;

// API Stuff
String apiKey = 'OPENAI_API_KEY';
const apiURL = 'https://api.openai.com/v1/chat/completions';

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

// String hiringManagerRole = '''
// You are an assistant that is helping extract structured information from a job posting and portfolio. 
// You are to give recommendations to an applicant that will most likely help them get an interview for a position.
// You are going to achieve this by comparing the job content to the applicant's portfolio and then providing recommendations.
// ''';

// String jobContentPrompt = '''Extract the following information from the job content, just digest it for now:''';

// String profContentPrompt = '''Extract the following information from the user's portfolio, just digest it for now:''';

// String returnPrompt = '''
// Return the recommendations in the following JSON format. 
// Ensure each field contains only the recommended names or items as specified, without any additional text or explanations. Capitalize each word. Keep each recommendation short and concise (one to four words). Sort the recommendations in alphabetical order.

// Ensure there are exactly:
//   - 2 education recommendations (CU Boulder and Colorado Mesa University)
//   - 3 experience recommendations
//   - 4 project recommendations (Include Taylor'd Portfolio every time)
//   - 15 math skill recommendations
//   - 15 personal skill recommendations
//   - All frameworks from the portfolio
//   - All programming languages from the portfolio
//   - 20 programming skill recommendations
//   - 15 scientific skill recommendations

// If any category does not meet the required number of recommendations, fill in the remainder with relevant skills for the job posting.

// Format your response as a JSON object:
// {
//     "Education_Recommendations": ["CU Boulder", "Colorado Mesa University"],
//     "Experience_Recommendations": ["Applied Materials", "University Of Oklahoma", "Mesa Lavender Farms"],
//     "Projects_Recommendations": ["Taylor'd Portfolio", "Project 2", "Project 3", "Project 4"],
//     "Math_Skills_Recommendations": ["Math Skill 1", "Math Skill 2", ..., "Math Skill 20"],
//     "Personal_Skills_Recommendations": ["Personal Skill 1", "Personal Skill 2", ..., "Personal Skill 15"],
//     "Framework_Recommendations": ["Framework 1", "Framework 2", ..., "Framework n"],
//     "Programming_Languages_Recommendations": ["Language 1", "Language 2", ..., "Language n"],
//     "Programming_Skills_Recommendations": ["Programming Skill 1", "Programming Skill 2", ..., "Programming Skill 20"],
//     "Scientific_Skills_Recommendations": ["Scientific Skill 1", "Scientific Skill 2", ..., "Scientific Skill 15"]
// }
// Ensure the response is a valid JSON object and nothing else.
// ''';

// final Map<String, dynamic> testOpenAIResults = {
//   "Education_Recommendations": ["The University Of Colorado At Boulder", "Colorado Mesa University"],
//   "Experience_Recommendations": ["Applied Materials", "University Of Oklahoma", "Mesa Lavender Farms"],
//   "Projects_Recommendations": ["Celestial Bodies In Space", "Formulator Pro", "RSA"],
//   "Math_Skills_Recommendations": [
//     "Computational Mathematics",
//     "Differential Equations",
//     "Fourier Analysis",
//     "Linear Algebra",
//     "Mathematical Modeling",
//     "Multivariate Calculus",
//     "Numerical Analysis",
//     "Probability Theory",
//     "Statistics",
//     "Tensor Analysis"
//   ],
//   "Personal_Skills_Recommendations": [
//     "Adaptability",
//     "Attention To Detail",
//     "Communication",
//     "Conflict Resolution",
//     "Critical Thinking",
//     "Decision Making",
//     "Leadership",
//     "Multitasking",
//     "Organization",
//     "Presentation Skills",
//     "Problem Solving",
//     "Project Management",
//     "Research Skills",
//     "Resourcefulness",
//     "Time Management"
//   ],
//   "Framework_Recommendations": ["ElectronJS", "Flutter", "Qt"],
//   "Programming_Languages_Recommendations": ["Python", "C/C++", "JavaScript", "Java", "Dart", "Assembly (x86)", "HTML", "CSS", "LATEX"],
//   "Programming_Skills_Recommendations": [
//     "Algorithms & Data Structures",
//     "Desktop & Mobile App Development",
//     "Documentation",
//     "Dynamic Programming",
//     "OOP Design",
//     "Quality Assurance",
//     "Scientific Programming",
//     "Software Design",
//     "Systems Level Development",
//     "Testing & Debugging",
//     "Unit Testing",
//     "Version Control",
//     "Web Development"
//   ],
//   "Scientific_Skills_Recommendations": [
//     "Computational Problem Solving",
//     "Data Analysis & Visualization",
//     "Error Analysis",
//     "Experimental Design",
//     "Laboratory Techniques",
//     "Literature Review",
//     "Plotting",
//     "Precision Measurement",
//     "Risk Assessment",
//     "Scientific Communication",
//     "Statistical Analysis",
//     "Technical Writing"
//   ]
// };
