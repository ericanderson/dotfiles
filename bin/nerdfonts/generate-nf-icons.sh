#!/bin/bash

# Get the directory where this script is located (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/../lib-common.sh"

# Initialize common setup
init_common "nerdfonts-generator"

# Paths
JSON_FILE="${SCRIPT_DIR}/../../dot_config/nerdfonts/glyphnames.json"
OUTPUT_FILE="${SCRIPT_DIR}/nf-icons.sh"

# Check if JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: glyphnames.json not found at $JSON_FILE"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Please install jq first."
  exit 1
fi

# Create the output file
echo "#!/bin/bash" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "# Nerd Font Icons - Generated from glyphnames.json" >> "$OUTPUT_FILE"
echo "# DO NOT EDIT MANUALLY" >> "$OUTPUT_FILE"
echo "# Generated on: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Add a comment with the original source
echo "# Original source: https://github.com/ryanoasis/nerd-fonts" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Begin the associative array declaration
echo "# Initialize the icons associative array" >> "$OUTPUT_FILE"
echo "declare -A icons" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract version info
version=$(jq -r '.METADATA.version' "$JSON_FILE" 2>/dev/null)
date=$(jq -r '.METADATA.date' "$JSON_FILE" 2>/dev/null)
echo "# Nerd Fonts Version: $version ($date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Start adding the icons
echo "# Icon definitions" >> "$OUTPUT_FILE"
echo "# Format: icons[NAME]='Unicode Character'  # Unicode Hex" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract and process icons from JSON (excluding METADATA)
echo "Processing JSON file..."

# Process each icon grouped by prefix
prefixes=(
  "cod-" 
  "dev-" 
  "fa-" 
  "fae-" 
  "iec-"
  "md-" 
  "oct-" 
  "ple-" 
  "pom-" 
  "seti-" 
  "weather-" 
  "linux-" 
  "custom-"
  "mdi-"
)

# Process icons by prefix group for better organization
for prefix in "${prefixes[@]}"; do
  # Add section header
  echo "" >> "$OUTPUT_FILE"
  echo "# $(echo $prefix | tr '[:lower:]' '[:upper:]')* Icons" >> "$OUTPUT_FILE"
  
  # Get icons with this prefix
  icons=$(jq -c "to_entries | map(select(.key | startswith(\"$prefix\"))) | sort_by(.key) | .[]" "$JSON_FILE")
  
  # Process icons
  echo "$icons" | while read -r line; do
    # Extract name and code
    name=$(echo "$line" | jq -r '.key')
    code=$(echo "$line" | jq -r '.value.code')
    
    # Skip if name or code is empty or null
    [[ -z "$name" || "$name" == "null" || -z "$code" || "$code" == "null" ]] && continue
    
    # Convert name to uppercase for variable name
    var_name=$(echo "$name" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    
    # Write to file with the formatted layout
    printf "icons[%-40s]='\\u%s'             # %s\n" "\"$var_name\"" "$code" "$name" >> "$OUTPUT_FILE"
  done
done

# Process any remaining icons that don't match known prefixes
echo "" >> "$OUTPUT_FILE"
echo "# Other Icons" >> "$OUTPUT_FILE"

# Get icons that don't match any known prefix
other_icons_filter="del(.METADATA)"
for prefix in "${prefixes[@]}"; do
  other_icons_filter="$other_icons_filter | with_entries(select(.key | startswith(\"$prefix\") | not))"
done

# Get other icons
other_icons=$(jq -c "$other_icons_filter | to_entries | sort_by(.key) | .[]" "$JSON_FILE")

# Process remaining icons
echo "$other_icons" | while read -r line; do
  # Extract name and code
  name=$(echo "$line" | jq -r '.key')
  code=$(echo "$line" | jq -r '.value.code')
  
  # Skip if name or code is empty or null
  [[ -z "$name" || "$name" == "null" || -z "$code" || "$code" == "null" ]] && continue
  
  # Skip METADATA
  [[ "$name" == "METADATA" ]] && continue
  
  # Convert name to uppercase for variable name
  var_name=$(echo "$name" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
  
  # Write to file with the formatted layout
  printf "icons[%-40s]='\\u%s'             # %s\n" "\"$var_name\"" "$code" "$name" >> "$OUTPUT_FILE"
done

# Add helper functions
cat >> "$OUTPUT_FILE" << 'EOF'

# Helper Functions

# Print specific icons by pattern
nf_print_icons() {
  local pattern="$1"
  if [[ -z "$pattern" ]]; then
    echo "Usage: nf_print_icons PATTERN"
    echo "Example: nf_print_icons 'FA_*'"
    return 1
  fi
  
  for key in "${!icons[@]}"; do
    if [[ "$key" == $pattern ]]; then
      printf "%-40s %s\n" "$key" "${icons[$key]}"
    fi
  done
}

# Show a demo of some common icons
nf_demo() {
  echo "Nerd Fonts Icon Demo:"
  echo "====================="
  echo ""
  echo "Font Awesome:       ${icons[FA_GITHUB]} ${icons[FA_HEART]} ${icons[FA_STAR]}"
  echo "Development:        ${icons[DEV_PYTHON]} ${icons[DEV_NODEJS]} ${icons[DEV_DOCKER]}"
  echo "VS Code:            ${icons[COD_ACCOUNT]} ${icons[COD_DEBUG_CONSOLE]} ${icons[COD_FOLDER]}"
  echo "Material Design:    ${icons[MD_ALERT]} ${icons[MD_CHECK]} ${icons[MD_SETTINGS]}"
  echo ""
  echo "For more icons, run: nf_print_icons 'FA_*'"
}

echo "Nerd Fonts icons loaded successfully."
echo "Run 'nf_demo' to see example icons."
echo "Run 'nf_print_icons \"FA_*\"' to list all Font Awesome icons."
EOF

# Make the file executable
chmod +x "$OUTPUT_FILE"

echo "Generation complete!"
echo "Output file: $OUTPUT_FILE"
echo ""
echo "To use in your scripts:"
echo "  source \"$OUTPUT_FILE\""
echo "  echo \"\${icons[FA_HEART]} Hello World\""
echo ""
echo "To test the icons:"
echo "  source \"$OUTPUT_FILE\" && nf_demo"