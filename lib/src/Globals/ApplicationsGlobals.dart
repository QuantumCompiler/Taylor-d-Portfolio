// Sizes
double applicationsContainerWidth = 0.8;

// API Stuff
String apiKey = 'OPENAI_API_KEY';
const apiURL = 'https://api.openai.com/v1/chat/completions';

// Server Address
// const latexServer = 'http://82.180.161.189:3000/compile';
const latexServer = 'http://10.0.0.102:3000/compile';

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

// Prompts
String covLetWhyMePrompt = "Why_Me_Pitch";
String covLetWhyJobPrompt = "Why_Job_Pitch";
String eduRecPrompt = "Education_Recommendations";
String expRecPrompt = "Experience_Recommendations";
String framRecPrompt = "Framework_Recommendations";
String mathSkillPrompt = "Math_Skills_Recommendations";
String persSkillPrompt = "Personal_Skills_Recommendations";
String projPrompt = "Project_Recommendations";
String progLangPrompt = "Programming_Languages_Recommendations";
String progSkillPrompt = "Programming_Skills_Recommendations";
String sciSkillPrompt = "Scientific_Skills_Recommendations";

// Files
String openAIRecsJSONFile = 'OpenAIRecs.json';
String openAICAboutMeTxtFile = 'OpenAICovLetAbout.txt';
String openAICLWJRecsTxtFile = 'OpenAICovLetWhyJob.txt';
String openAICLWMRecsTxtFile = 'OpenAICovLetWhyMe.txt';
String openAIEduRecsTxtFile = 'OpenAIEduRecs.txt';
String openAIExpRecsTxtFile = 'OpenAIExpRecs.txt';
String openAIFramRecsTxtFile = 'OpenAIFramRecs.txt';
String openAIMathRecsTxtFile = 'OpenAIMathRecs.txt';
String openAIPersRecsTxtFile = 'OpenAIPersRecs.txt';
String openAIPLRecsTxtFile = 'OpenAIProgLangRecs.txt';
String openAIPSRecsTxtFile = 'OpenAIProgSkillsRecs.txt';
String openAIProjRecsTxtFile = 'OpenAIProjRecs.txt';
String openAISciRecsTxtFile = 'OpenAISciRecs.txt';

// Final Portfolio Files
String finCLAboutFile = 'About.txt';
String finCLCompFile = 'Company.txt';
String finCLJobFile = 'Job.txt';
String finCLMeFile = 'Me.txt';
String finEduRecFile = 'Education.txt';
String finExpRecFile = 'Experience.txt';
String finFramFile = 'Frameworks.txt';
String finLangFile = 'Languages.txt';
String finMathRecFile = 'Math.txt';
String finPersRecFile = 'Personal.txt';
String finProgRecFile = 'Programming.txt';
String finProjRecFile = 'Projects.txt';
String finSciRecFile = 'Scientific.txt';

// Backend Stuff
String localLaTeX = 'http://localhost:3000/compile';
String vpsLaTeX = 'http://82.180.161.189:3000/compile';

String hiringManagerRole = '''
You are an assistant that is helping extract structured information from a job posting and portfolio. 
You are to give recommendations to an applicant that will most likely help them get an interview for a position.
You are going to achieve this by comparing the job content to the applicant's portfolio and then providing recommendations.
''';

String jobContentPrompt = '''Extract the following information from the job content, just digest it for now:\n''';

String profContentPrompt = '''Extract the following information from the user's portfolio, just digest it for now:\n''';

String returnPrompt = '''
Return the recommendations in the following JSON format. Ensure each field contains only the recommended names or items as specified, without any additional text or explanations. Capitalize each word. Keep each recommendation short and concise (one to four words). Sort the recommendations in alphabetical order.

Ensure there are exactly:
  - $covLetWhyMePrompt: A 400 word cover letter entry for why the applicant would be a good candidate (make sure to create line breaks for each separate paragraph)
  - $covLetWhyJobPrompt: A 400 word cover letter entry for why the applicant would want to work at the job (make sure to create line breaks for each separate paragraph)
  - $eduRecPrompt: 2 education recommendations (the name of the school, prioritize experiences were degrees were rewarded and those currently in progress)
  - $expRecPrompt: 3 experience recommendations (the name of the workplace, prioritize experiences that closely align to the job being applied to)
  - $framRecPrompt: All frameworks from the portfolio
  - $mathSkillPrompt: 15 math skill recommendations
  - $persSkillPrompt: 15 personal skill recommendations
  - $projPrompt: 4 project recommendations (Prioritize full stack applications / projects)
  - $progLangPrompt: All programming languages from the portfolio
  - $progSkillPrompt: 20 programming skill recommendations
  - $sciSkillPrompt: 15 scientific skill recommendations

If any category does not meet the required number of recommendations, fill in the remainder with relevant skills for the job posting.

Format your response as a JSON object:
{
  "$covLetWhyMePrompt": ["Why me cover letter pitch."],
  "$covLetWhyJobPrompt": ["Why job cover letter pitch"],
  "$eduRecPrompt": ["Education Recommendation 1", "Education Recommendation 2"],
  "$expRecPrompt": ["Experience Recommendation 1", "Experience Recommendation 2", "Experience Recommendation 3"],
  "$framRecPrompt": ["Framework 1", ..., "Framework n"],
  "$mathSkillPrompt": ["Math Skill 1", ..., "Math Skill 20"],
  "$persSkillPrompt": ["Personal Skill 1", ..., "Personal Skill 15"],
  "$projPrompt": ["Project 1", ..., "Project 4"],
  "$progLangPrompt": ["Language 1", ..., "Language n"],
  "$progSkillPrompt": ["Programming Skill 1", ..., "Programming Skill 20"],
  "$sciSkillPrompt": ["Scientific Skill 1", ..., "Scientific Skill 15"]
}
Ensure the response is a valid JSON object and nothing else.
''';

final Map<String, dynamic> testOpenAIResults = {
  "Why_Me_Pitch": [
    "With a strong background in computer science and over two years of experience tackling complex problems in software development, I am excited about the opportunity to contribute to the Platform Engineering team at TrainingPeaks. My proficiency with various cloud and DevOps technologies such as AWS, Kubernetes, and Docker, combined with my scripting skills in Python and Bash, make me an ideal candidate to build and maintain reliable and scalable platforms.",
    "I have developed my expertise in continuous integration/deployment, infrastructure as code, and system monitoring through various roles and personal projects. This, coupled with my commitment to continuous learning and improving both myself and the teams I work with, positions me to add immediate value to your team. I look forward to the opportunity to bring my skills and passion to TrainingPeaks."
  ],
  "Why_Job_Pitch": [
    "Working at TrainingPeaks aligns perfectly with my career goals as it offers the chance to create impactful solutions for a rapidly growing user base of athletes and coaches. The opportunity to collaborate closely with other talented engineers and contribute to an ever-evolving platform that improves users' training experiences is exciting and motivating.",
    "I am particularly drawn to TrainingPeaks due to its reputation for innovation and dedication to building the world's best training platform. The diversity of brands under the Peaksware umbrella indicates a dynamic work environment and a commitment to excellence across various domains, from endurance training to music education. I am enthusiastic about joining such a collaborative and forward-thinking team."
  ],
  "Education_Recommendations": ["The University Of Colorado At Boulder", "Colorado Mesa University"],
  "Experience_Recommendations": ["Applied Materials", "Mesa Lavender Farms", "University Of Oklahoma"],
  "Framework_Recommendations": ["ElectronJS", "Flask", "Flutter", "Qt", "React"],
  "Math_Skills_Recommendations": [
    "Computational Mathematics",
    "Differential Equations",
    "Discrete Mathematics",
    "Fourier Analysis",
    "Linear Algebra",
    "Mathematical Modeling",
    "Multivariate Calculus",
    "Numerical Analysis",
    "Probability Theory",
    "Statistics"
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
  "Project_Recommendations": ["Celestial Bodies In Space", "Formulator Pro", "Recipe Genie", "Taylor'd Portfolio"],
  "Programming_Languages_Recommendations": ["Assembly (x86)", "C/C++", "CSS", "Dart", "HTML", "Java", "JavaScript", "LATEX", "Python", "Scala"],
  "Programming_Skills_Recommendations": [
    "AI and Machine Learning",
    "Agile Development",
    "Algorithms",
    "Data Cleaning and Preprocessing",
    "Data Structures",
    "Data Visualization",
    "Desktop & Mobile App Development",
    "Documentation",
    "Formal Logic and Proof Techniques",
    "Graph Algorithms",
    "OOP Design",
    "Process Management",
    "Quality Assurance and Testing",
    "Regression Analysis",
    "Software Design",
    "Systems Level Development",
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

final Map<String, dynamic> testOpenAIResults2 = {
  "Why_Me_Pitch": [
    "As a passionate Platform Engineer with extensive experience in solving complex problems and creating impactful solutions, I am drawn to the opportunity at TrainingPeaks. Graduating Cum Laude with a B.S. in Physics and a minor in Mathematics, my analytical skills and rigorous problem-solving approach have been honed over years of academic and professional experience. Currently furthering my expertise in computer science through CU Boulder’s online post-baccalaureate program, I blend physics, mathematics, and computer science to approach challenges from multiple perspectives, driving innovation across disciplines.",
    "At Applied Materials, I automated processes using Python, enhancing efficiency in daily tasks. As a Formulation Scientist and Software Developer at Mesa Lavender Farms, I developed full-stack applications that streamlined operations and improved productivity. My experience in teaching and scientific analysis, combined with software development, enables me to contribute effectively to a collaborative team environment.",
    "My background aligns with the requirements of a Platform Engineer. My familiarity with modern Cloud/DevOps topics, including AWS, Kubernetes, Docker, and Terraform, alongside proficiency in scripting languages such as Python, demonstrates my capability to build and maintain reliable platforms. Additionally, my commitment to continuous learning and improvement is evident through my proactive approach to personal and professional development.",
    "Joining TrainingPeaks would allow me to work on innovative projects that impact millions of users, fostering a culture of collaboration and excellence. I look forward to contributing my expertise to enhance the platform's infrastructure, ensuring it meets the growing demands of athletes and coaches. Together, we can build the world’s best training platform, driving progress and achieving remarkable success."
  ],
  "Why_Job_Pitch": [
    "The opportunity to work at TrainingPeaks excites me because of its impact on millions of athletes and coaches worldwide. The prospect of joining a team dedicated to building the best training platform aligns with my passion for creating impactful solutions. TrainingPeaks’ commitment to innovation and collaboration is particularly appealing, as it resonates with my approach to continuous learning and improvement.",
    "Being part of an organization under the Peaksware umbrella allows me to contribute to diverse projects across different brands like MakeMusic, TrainHeroic, and Alfred Music. This aligns with my interdisciplinary background, blending physics, mathematics, and computer science, enabling me to innovate across various domains.",
    "Joining TrainingPeaks represents an opportunity to work on complex challenges alongside skilled professionals, fostering a culture of excellence and teamwork. Collaborating closely with Product Managers, Software Engineers, and QA to design and maintain essential platforms aligns perfectly with my professional aspirations and skills.",
    "The inclusive and diverse workplace environment at TrainingPeaks, offering equal opportunity regardless of gender, race, or background, reassures me that my contributions will be valued and supported. I am eager to be part of a team that values adaptability, continuous learning, and a dedication to excellence, contributing to the growth and success of TrainingPeaks."
  ],
  "Education_Recommendations": ["The University Of Colorado At Boulder", "Colorado Mesa University"],
  "Experience_Recommendations": ["Applied Materials", "Mesa Lavender Farms", "University Of Oklahoma"],
  "Framework_Recommendations": ["ElectronJS", "Flask", "Flutter", "Qt", "React"],
  "Math_Skills_Recommendations": [
    "Computational Mathematics",
    "Discrete Mathematics",
    "Differential Equations",
    "Fourier Analysis",
    "Linear Algebra",
    "Mathematical Modeling",
    "Mathematical Physics",
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
  "Project_Recommendations": ["EZ-Blackjack", "Formulator Pro", "Recipe Genie", "Taylor'd Portfolio"],
  "Programming_Languages_Recommendations": ["Assembly (x86)", "C/C++", "CSS", "Dart", "HTML", "Java", "JavaScript", "LATEX", "Python", "Scala"],
  "Programming_Skills_Recommendations": [
    "AI And Machine Learning",
    "Agile Development",
    "Algorithms",
    "Clustering And Classification",
    "Concurrency",
    "Cryptography",
    "Data Cleaning And Preprocessing",
    "Data Structures",
    "Data Visualization",
    "Debugging Tools",
    "Formal Logic And Proof Techniques",
    "Functional Programming",
    "Graph Algorithms And Theory",
    "Inductive Definitions And Type Systems",
    "Natural Language Processing",
    "Network Flow And Shortest Path Algorithms",
    "Object-Oriented Programming Design",
    "Python For AI",
    "Regression Analysis",
    "Version Control"
  ],
  "Scientific_Skills_Recommendations": [
    "Computational Problem Solving",
    "Data Analysis And Visualization",
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
