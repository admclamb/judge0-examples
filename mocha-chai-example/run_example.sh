# Generate the request body with source code, stdin, and additional files encoded in Base64.
function generate_request_body() {
    cat << EOF
{
    "source_code": "$(cat script.js | $JUDGE0_BASE64_CMD -w0 -)",
    "stdin": "$(cat stdin.txt | $JUDGE0_BASE64_CMD -w0 -)",
    "language_id": 89,
    "additional_files": "$(cd additional_files; zip -r - . | $JUDGE0_BASE64_CMD -w0 -)"
}
EOF
}

# Create a submission by posting the request body to the Judge0 API.
function create_submission() {
    echo "[$(date)] Generating request body..." 1>&2
    generate_request_body > request_body.json
    echo "[$(date)] Creating submission..." 1>&2
    curl --progress-bar \
         --no-silent \
         -X POST \
         -H "Content-Type: application/json" \
         -H "X-RapidAPI-Key: $RAPIDAPI_KEY" \
         -H "X-RapidAPI-Host: judge0-ce.p.rapidapi.com" \
         --data @request_body.json \
         --output request_response.json \
         "$JUDGE0_CE_BASE_URL/submissions?base64_encoded=true&wait=false"
    cat request_response.json
}

# Retrieve submission details from Judge0 using the provided token and desired fields.
function get_submission() {
    curl -H "Accept: application/json" \
         -H "X-RapidAPI-Key: $RAPIDAPI_KEY" \
         -H "X-RapidAPI-Host: judge0-ce.p.rapidapi.com" \
         "$JUDGE0_CE_BASE_URL/submissions/$1?base64_encoded=true&fields=$2"
}

# Create a submission and extract the token.
token="$(create_submission | jq -r ".token")"
if [[ "$token" == "null" ]]; then
    cat request_response.json | jq
    exit 1
fi

echo "[$(date)] Token: $token"

# Poll for the submission result until the status is no longer "In Queue" (1) or "Processing" (2)
for i in {1..10}; do
    sleep $(( i / 2 ))
    status_id="$(get_submission "$token" "status" | jq -r ".status.id")"
    echo "[$(date)] Status ID: $status_id"
    if [[ "$status_id" != "1" && "$status_id" != "2" ]]; then
        break
    fi
done

# Retrieve the submission response with selected fields.
submission_json="$(get_submission "$token" "status,stdout,stderr,compile_output,message")"

echo "[$(date)] Received submission:"
echo "$submission_json" | jq

# --- Generate Output Files ---

# Create the output folder if it doesn't exist.
mkdir -p output

# Save the raw JSON response.
echo "$submission_json" | jq '.' > output/response.json

# Function to decode a Base64 field from the JSON and save it to a file.
function decode_field() {
    local field="$1"
    local outfile="$2"
    local content
    content=$(echo "$submission_json" | jq -r ".${field}")
    if [[ "$content" == "null" || -z "$content" ]]; then
        echo "N/A" > "$outfile"
    else
        echo "$content" | $JUDGE0_BASE64_CMD -d - > "$outfile"
    fi
}

# Decode each field into its corresponding file.
decode_field "stdout" "output/stdout.txt"
decode_field "stderr" "output/stderr.txt"
decode_field "compile_output" "output/compile_output.txt"
decode_field "message" "output/message.txt"

# Create a human-readable summary file.
{
    echo "Submission Status: $(echo "$submission_json" | jq -r '.status.description')"
    echo "----------------------------------------"
    echo "Standard Output:"
    cat output/stdout.txt
    echo ""
    echo "Standard Error:"
    cat output/stderr.txt
    echo ""
    echo "Compile Output:"
    cat output/compile_output.txt
    echo ""
    echo "Message:"
    cat output/message.txt
} > output/readable_response.txt

echo "[$(date)] Readable response generated in the output folder."