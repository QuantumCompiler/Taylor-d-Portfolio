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

String hiringManagerRole = ''' You are an assistant that is helping extract structured information from a job posting and portfolio. 
You are to give recommendations to an applicant that will most likely help them get an interview for a position.
You are going to achieve this by comparing the job content to the applicant's portfolio and then providing recommendations.
''';

String jobContentPrompt = ''' Extract the following information from the job content, just digest it for now. It will be fed to you in this format:
- Job Description:
- Other Information:
- Position Information:
- Qualifications Information:
- Role Information:
- Tasks Information:
Input:
''';

String profContentPrompt = ''' Extract the following information from the users portfolio, just digest it for now. It will be fed to you in this format:
- Education:
- Experience:
- Extracurricular:
- Honors:
- Projects:
- References:
- Skills:
Input:
''';

String returnPrompt = '''Return the recommendations in the following JSON Format. 
Ensure each field contains only the recommended names or items as specified, without any additional text or explanations. Keep each recommendation short and concise (one to four words):
{
  "Education_Recommendations": ["Name of School", "Another School"],
  "Experience_Recommendations": ["Workplace 1", "Workplace 2"],
  "Projects_Recommendations": ["Project 1", "Project 2"],
  "Math_Skills_Recommendations": ["Skill 1", "Skill 2"],
  "Personal_Skills_Recommendations": ["Skill 1"],
  "Framework_Recommendations": ["Framework 1"],
  "Programming_Languages_Recommendations": ["Language 1"],
  "Programming_Skills_Recommendations": ["Skill 1"],
  "Scientific_Skills_Recommendations": ["Skill 1"]
}
Make sure the response is a valid JSON object and nothing else. Only include the names of the schools, workplaces, and projects that you recommend. Keep the recommendations for skills, frameworks, and languages to one to four words.
''';
