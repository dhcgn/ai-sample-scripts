---
applyTo: "**/*.sh"
---

# Bash Scripting Best Practices and Guidelines

## Introduction

This document defines the mandatory coding standards and best practices for all bash scripts in this repository. These guidelines ensure consistency, security, maintainability, and reliability across all shell scripts.

**Why These Standards Matter:**
- **Security**: Prevents hardcoded API keys and sensitive data exposure
- **Reliability**: Ensures proper error handling and cleanup mechanisms
- **Maintainability**: Creates consistent, readable code that's easy to debug
- **Compliance**: Enforces ShellCheck linting for robust script quality
- **AI Assistance**: Enables GitHub Copilot to generate high-quality, consistent code

**Mandatory Requirements:**
- ALL scripts MUST follow these patterns and structures
- ALL scripts MUST pass ShellCheck linting without warnings
- ALL scripts MUST include proper cleanup, logging, and error handling
- ALL scripts MUST validate inputs and environment requirements
- NO sensitive data (API keys, passwords) may be hardcoded in scripts

The script must be compliant with ShellCheck - A shell script static analysis tool.

## Mandatory Script Structure

### 1. Script Header and Environment Validation
```bash
#!/bin/bash

# Script description and documentation links if applicable

# Check for required environment variables early
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    exit 1
fi

# Check for required commands at the beginning
for cmd in identify jq curl base64; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        if [ "$cmd" = "identify" ]; then
            echo "Please install ImageMagick to proceed." >&2
        fi
        exit 1
    fi
done
```

### 2. Usage and Help Functions
```bash
# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_image>"
    echo "Example: $0 /path/to/image.jpg"
    echo "Note: Image must be 1024x1024 pixels or smaller"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi
```

### 3. Temporary Files and Cleanup Management
```bash
# Function to clean up temporary files
cleanup() {
    rm -f "$TEMP_BASE64_FILE" "$TEMP_JSON_FILE"
    # Clean up any other temporary files
    rm -f "$temp_image"
}

# Set up trap to clean up temporary files on script exit
trap cleanup EXIT

# Create temporary files
TEMP_BASE64_FILE=$(mktemp)
TEMP_JSON_FILE=$(mktemp)
```

### 4. JSON Handling with jq
```bash
# Use jq for safe JSON string escaping
cat > "$TEMP_JSON_FILE" << EOF
{
    "model": "gpt-4o-2024-08-06",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": $(printf '%s' "$PROMPT" | jq -R .)
                }
            ]
        }
    ]
}
EOF

# Validate JSON syntax before using
if ! jq empty "$TEMP_JSON_FILE" 2>/dev/null; then
    echo "Error: Generated JSON is invalid"
    exit 1
fi

# Extract data safely with jq
content=$(echo "$response" | jq -r '.choices[0].message.content // "ERROR: No content found"')
```

### 5. Structured Logging System
```bash
# Create timestamp for logging
timestamp=$(date +"%Y%m%d_%H%M%S")

# Ensure logging directory exists
mkdir -p logging

# Save response and request (without sensitive data)
echo "$response" > "logging/$timestamp.response.json"
jq 'del(.messages[0].content[1].image_url.url)' "$TEMP_JSON_FILE" > "logging/$timestamp.request.json"

# Save human-readable output
echo "$content" > "logging/$timestamp.response.md"
```

### 6. API Interaction Best Practices
```bash
# Test if the API endpoint is reachable and has the required model
echo "Testing API endpoint..."
models_response=$(curl -s "$API_URL/v1/models")
if ! echo "$models_response" | jq -e '.data[] | select(.id == "required-model-name")' > /dev/null; then
    echo "Error: Required model 'required-model-name' not found"
    echo "Available models:"
    echo "$models_response" | jq -r '.data[].id // "No models found"'
    exit 1
fi

# Make API calls with proper error handling
response=$(curl -s "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d @"$TEMP_JSON_FILE")

# Check if curl succeeded
if [ $? -ne 0 ]; then
    echo "Error: API call failed" >&2
    exit 1
fi
```

### 7. Multiline String Declaration
```bash
# Use read with here-doc for better readability
read -r -d '' PROMPT << EOM
You job is to extract text from the images I provide you. 
Extract every bit of the text in the image. 
Don't say anything just do your job.

Things to avoid:
- Don't miss anything to extract from the images

Things to include:
- Include everything, even anything inside [], (), {} or anything.
- Include any repetitive things like "..." or anything
EOM
```

### 8. File Validation and Processing
```bash
# Case-insensitive file extension check
if [[ ! "${IMAGE_FILE,,}" =~ \.(jpg|jpeg|png)$ ]]; then
    echo "Error: The image file must be a jpg, jpeg, or png file." >&2
    usage
fi

# Check file existence
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file does not exist: $IMAGE_FILE" >&2
    exit 1
fi

# Check file dimensions (example with ImageMagick)
dimensions=$(identify -format "%wx%h" "$IMAGE_FILE")
width=$(echo "$dimensions" | cut -d'x' -f1)
height=$(echo "$dimensions" | cut -d'x' -f2)

if [ "$width" -gt 1024 ] || [ "$height" -gt 1024 ]; then
    echo "Image dimensions ($dimensions) exceed maximum size. Resizing..."
    temp_image=$(mktemp --suffix=.jpg)
    convert "$IMAGE_FILE" -resize 1024x1024\> "$temp_image"
    IMAGE_FILE="$temp_image"
    trap 'rm -f "$temp_image"' EXIT
fi
```

## Security Requirements

### Never Include Sensitive Data
- ❌ NEVER hardcode API keys: `API_KEY="sk-1234567890abcdef"`
- ✅ Always use environment variables: `if [ -z "$OPENAI_API_KEY" ]; then`
- ✅ Sanitize logging: `jq 'del(.messages[0].content[1].image_url.url)' "$TEMP_JSON_FILE"`

## Error Handling and User Feedback

### Informative Error Messages
```bash
# Provide context in error messages
echo "Error: Image file does not exist: $IMAGE_FILE" >&2
echo "Please check the file path and try again." >&2

# Show progress for long operations
echo "Processing file: $IMAGE_FILE ($dimensions)"
echo "Resizing image to meet size requirements..."

# Track response time
start_time=$(date +%s)
# ... API call ...
end_time=$(date +%s)
response_time=$((end_time - start_time))
echo "Request-to-response time: ${response_time} seconds"
```

## ShellCheck Compliance Rules

### Critical ShellCheck Fixes
- Quote variables: Use `"$variable"` instead of `$variable`
- Check command existence: Use `command -v "$cmd" &> /dev/null`
- Proper conditionals: Use `[[ ]]` for bash, `[ ]` for POSIX
- Array handling: Use `"${array[@]}"` for arrays
- Exit codes: Always check and handle exit codes properly

### Common Patterns to Avoid
```bash
# ❌ Unquoted variables
if [ $# -ne 1 ]; then

# ✅ Quoted variables  
if [ "$#" -ne 1 ]; then

# ❌ Useless cat
cat file | grep pattern

# ✅ Direct input
grep pattern file

# ❌ Legacy command substitution
result=`command`

# ✅ Modern command substitution
result=$(command)
```

# Linter rules

* **Loop and Function Syntax**

  * Ensure `do`/`done` pairs match (SC1058, SC1061, SC1062).
  * Use `{}` to start function bodies and a space between name and body (SC1064, SC1095).
  * Replace `else if` with `elif` (SC1075, SC1131).

* **Shebang and Encoding**

  * Shebang must start with `#!` on the first line, with no leading spaces or extra characters (SC1084, SC1104, SC1113, SC1114, SC1115, SC1128, SC1129).
  * Remove UTF-8 BOM or unicode quotes/dashes; retype as ASCII if needed (SC1082, SC1100, SC1110–SC1112).

* **Assignments and Variables**

  * Don’t prefix variable names with `$` when assigning; use `var=value` and no spaces around `=` (SC1065, SC1066, SC1068, SC1108).
  * Quote variable expansions and array indices (`"${var}"`, `${array[idx]}`) to prevent word splitting (SC1087, SC2128, SC2129, SC2141, SC2142, SC2146, SC2147, SC2148, SC2210).
  * Use `"$@"` inside functions to forward all arguments (SC2120, SC2121).
  * Avoid assigning pipeline outputs in subshells if you need the modified value later (SC2030, SC2031, SC2124).
  * Use `$((…))` for arithmetic, not legacy backticks or unquoted expansions (SC1097, SC2006, SC2007, SC2099, SC2100, SC2126, SC2127).

* **Quoting and Escaping**

  * Always quote patterns or strings used by `grep`, `tr`, `find`, etc., to prevent shell interpretation (SC2001, SC2008–SC2009, SC2020–SC2021, SC2022, SC2035, SC2038, SC2039, SC2046, SC2060, SC2061, SC2062, SC2063, SC2072, SC2073, SC2076, SC2077, SC2086, SC2090).
  * Escape `$` to use it literally inside double quotes (SC1135).
  * Use `printf` instead of `echo` when you need escape-sequence processing or to avoid silent failures (SC2028, SC2034, SC2036, SC2046, SC2130, SC2182, SC2183, SC2184).

* **Test and Conditionals**

  * Put spaces around `[` and `]` and use `[[ … ]]` for complex tests (SC1069, SC1117, SC1119, SC1130, SC1132, SC1133, SC1136, SC1140 series, SC2077, SC2080, SC2093, SC2094, SC2097, SC2137–SC2139).
  * Replace `-a`/`-o` in `[` tests with `&&`/`||`, or use separate tests (SC2057–SC2058, SC2070–SC2071, SC2074, SC2078–SC2079, SC2127, SC2143, SC2144).
  * Use `-gt`/`-lt` for numeric comparisons, not `>`/`<` (SC2071, SC2122, SC2123).

* **Redirections and Pipelines**

  * Don’t pipe into `echo`; consider `printf` or redirect properly (SC2008).
  * Avoid `ls | grep`; use globs or `find -exec` to handle special filenames reliably (SC2010–SC2012).
  * Use `find -print0`/`xargs -0` or `find -exec` to handle non-alphanumeric names (SC2011–SC2012, SC2040, SC2088, SC2089).
  * Redirect stderr with `2>&1` at the end or use `{ cmd; } 2>&1` (SC2069).

* **Array and Loop Best Practices**

  * In `for` loops, don’t prefix the iterator with `$`; loop over actual items or indices (SC1086, SC2043, SC2044).
  * Quote array expansions to prevent unintended splitting (`"${array[@]}"`) (SC2146, SC2147).
  * Use `read -r` or `mapfile` to read lines safely, instead of splitting on whitespace (SC2013, SC2207).

* **Command Substitution and Eval**

  * Favor `$(cmd)` over backticks; add spaces (`$( cmd )` vs. backticks) to avoid parsing errors (SC1077, SC2006, SC1120–SC1122, SC2128, SC2129).
  * Quote or escape content passed to `eval` to avoid injection and parsing pitfalls (SC1098, SC1117).

* **Here-Docs**

  * No comments after a here-doc delimiter; put them on the next line (SC1120).
  * Ensure the end token is on its own line, with no trailing whitespace (SC1118–SC1122).

* **Sourcing and Directives**

  * ShellCheck only supports POSIX-compatible shells; don’t source non-constant files without a directive (SC1090–SC1091, SC1094).
  * Place any ShellCheck directives (`# shellcheck …`) before the entire compound command — not in the middle of an `if` or `case` (SC1126–SC1127, SC1123–SC1124, SC1125).
  * Invalid or misplaced directives will be ignored (SC1107, SC1135).

* **Miscellaneous Warnings**

  * Avoid useless `cat`/`echo` around commands; use redirection or pass filenames directly (SC2002–SC2005).
  * Don’t mix string and array variables improperly; declare arrays with `()` and expand them correctly (SC2124–SC2128, SC2135–SC2136).
  * Watch for unintended literal strings versus commands (SC2041, SC2160–SC2162).
  * Ensure loops, case patterns, and functions aren’t masked by earlier definitions or incorrect indexing (SC2033, SC2139–SC2150, SC2188–SC2191).
  * Avoid deprecated or non-portable syntax (SC2096–SC2098, SC2124, SC2160, SC2162, SC2190).

Each rule category focuses on syntax correctness, quoting/escaping, POSIX-compliance, and robust scripting practices—use it as a quick reference when writing or reviewing shell scripts.
