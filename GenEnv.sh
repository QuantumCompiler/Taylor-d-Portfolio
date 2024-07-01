inputFile="/Users/taylor/Library/Mobile Documents/com~apple~CloudDocs/Documents/General/Technology/Open AI/API Keys.txt"
outputFile=".env"
prepend="OPENAI_API_KEY="

if [ -f "$outputFile" ]; then
    echo ".env file already exists."
else
    if [ -f "$inputFile" ]; then
        apiKey=$(<"$inputFile")
        echo "${prepend}${apiKey}" > "$outputFile"
        echo "Created .env file with API key in $outputFile."
    else
        echo "API key is missing."
    fi
fi