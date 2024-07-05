import json
import sys
import os

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def escape_content(content):
    return content.replace('\n', '\\n').replace('"', '\\"').replace("'", "\\'")

def main(job_posting_file, portfolio_file, output_file):
    # Check if files have the correct .txt extension
    if not job_posting_file.endswith('.txt') or not portfolio_file.endswith('.txt'):
        print("Error: Both job posting and portfolio files must be .txt files.")
        return
    
    # Read the job posting and portfolio from text files
    job_posting = read_file(job_posting_file)
    portfolio = read_file(portfolio_file)

    # Escape content for JSON
    job_posting = escape_content(job_posting)
    portfolio = escape_content(portfolio)

    # Define the system message
    system_message = '''
You are an assistant that is helping extract structured information from a job posting and portfolio.
You are to give recommendations to an applicant that will most likely help them get an interview for a position.
You are going to achieve this by comparing the job content to the applicant's portfolio and then providing recommendations.
'''

    # Define the user prompt parts
    user_prompt_part1 = '''Extract the following information from the job content, just digest it for now. It will be fed to you in this format:
Job Description:
Other Information:
Qualifications Information:
Role Information:
Input:
'''

    # Define the user portfolio prompt
    user_portfolio_prompt = '''
Extract the following information from the user's portfolio, just digest it for now. It will be fed to you in this format:
Education:
Experience:
Projects:
Skills:
Input:
'''

    # Combine the prompts, job posting, and portfolio
    user_prompt = f"{user_prompt_part1}\\n{job_posting}\\n{user_portfolio_prompt}\\n{portfolio}"

    # Define the assistant response
    assistant_response = '''
Return the recommendations in the following JSON Format. 
Ensure each field contains only the recommended names or items as specified, without any additional text or explanations. Capitalize every new word. Keep each recommendation short and concise (one to four words):
{
    "Education_Recommendations": ["School Name 1", "School Name 2"]
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
'''

    # Create the JSONL entry
    jsonl_entry = {
        "messages": [
            {
                "role": "system",
                "content": system_message.strip()
            },
            {
                "role": "user",
                "content": user_prompt.strip()
            },
            {
                "role": "assistant",
                "content": assistant_response.strip()
            }
        ]
    }

    # Convert to JSON string
    jsonl_string = json.dumps(jsonl_entry)

    # Write the JSONL entry to a file
    with open(output_file, 'w') as jsonl_file:
        jsonl_file.write(jsonl_string + '\n')

    print(f"JSONL file '{output_file}' created successfully.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <job_posting_file> <portfolio_file> <output_file>")
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])