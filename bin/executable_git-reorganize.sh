#!/bin/bash
#
# git-reorganize: Reorganize git repositories to follow Go-style paths
# Usage: git-reorganize [--dry-run] [--max-depth N] /path/to/search
#

set -euo pipefail

# Constants
TARGET_BASE="/Volumes/git"
LOG_FILE="$HOME/.git-reorganize.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Colors and formatting
if [[ -t 1 ]]; then
  RESET="\033[0m"
  BOLD="\033[1m"
  DIM="\033[2m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  CYAN="\033[36m"
  GRAY="\033[90m"
else
  # No colors if not in a terminal
  RESET=""
  BOLD=""
  DIM=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  GRAY=""
fi

# Icons
ICON_SUCCESS="✓"
ICON_WARNING="⚠️"
ICON_SKIP="✗"
ICON_MOVE="→"

# Variables
DRY_RUN=0
SEARCH_DIR=""
REPOS_FOUND=0
REPOS_MOVED=0
REPOS_SKIPPED=0
REPO_COUNTER=0
REPO_LIMIT=0  # 0 means no limit

# Arrays to store skip reasons
declare -a NO_REMOTE_REPOS
declare -a TARGET_EXISTS_REPOS
declare -a TARGET_EXISTS_DIRTY_REPOS
declare -a URL_FORMAT_REPOS
declare -a PARSING_ERROR_REPOS
declare -a SOURCE_GONE_REPOS
declare -a WORKTREE_REPOS
declare -a SUBMODULE_REPOS
declare -a BARE_REPOS

# Function to log messages with timestamp
log_message() {
  local message="$1"
  local log_only="${2:-false}"
  
  # Always log to file
  echo "[$TIMESTAMP] $message" >> "$LOG_FILE"
  
  # Optionally output to screen
  if [[ "$log_only" == "false" ]]; then
    echo -e "$message"
  fi
}

# Format a path highlighting the unique part
format_path() {
  local path="$1"
  local prefix="$TARGET_BASE/"
  
  if [[ "$path" == "$prefix"* ]]; then
    echo -n "${GRAY}#/${RESET}${BOLD}${path#$prefix}${RESET}"
  else
    echo -n "$path"
  fi
}

# Function to print usage
usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--limit N] <directory>"
  echo "  Recursively find git repositories and reorganize them to follow Go-style paths"
  echo "  Options:"
  echo "    --dry-run     Don't actually move anything, just show what would happen"
  echo "    --limit N     Process at most N repositories (0 means no limit)"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --limit)
      if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --limit requires a numeric argument"
        usage
      fi
      REPO_LIMIT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$SEARCH_DIR" ]]; then
        SEARCH_DIR="$1"
      else
        echo "Error: Multiple search directories specified"
        usage
      fi
      shift
      ;;
  esac
done

# Validate arguments
if [[ -z "$SEARCH_DIR" ]]; then
  echo "Error: No search directory specified"
  usage
fi

if [[ ! -d "$SEARCH_DIR" ]]; then
  echo "Error: Directory '$SEARCH_DIR' does not exist"
  exit 1
fi

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Print operation mode
if [[ $DRY_RUN -eq 1 ]]; then
  log_message "Running in DRY RUN mode - no files will be moved"
else
  log_message "Running in LIVE mode - repositories will be moved"
fi

log_message "Searching for git repositories in: $SEARCH_DIR"
log_message "Target base directory: $TARGET_BASE"
log_message "Detailed log: $LOG_FILE"

# Function to extract remote URL and convert to target path
extract_repo_info() {
  local git_dir="$1"
  local repo_dir="${git_dir%/.git}"
  
  # Check if source still exists (in case parent was already moved)
  if [[ ! -d "$repo_dir" ]]; then
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[source no longer exists]${RESET}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (source directory no longer exists, likely moved with parent)" true
    SOURCE_GONE_REPOS+=("$repo_dir")
    return 1
  fi
  
  # Skip if this is part of a worktree
  if [[ -f "$git_dir/commondir" ]]; then
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[git worktree]${RESET}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (is a git worktree)" true
    WORKTREE_REPOS+=("$repo_dir")
    return 1
  fi

  # Check if this is a git submodule
  if [[ -f "$git_dir/config" ]] && grep -q "\[core\]" "$git_dir/config" && grep -q "repositoryformatversion = 0" "$git_dir/config" && [[ -d "$(dirname "$repo_dir")/.git" ]]; then
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[git submodule]${RESET}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (is a git submodule)" true
    SUBMODULE_REPOS+=("$repo_dir")
    return 1
  fi
  
  # Check if this is a bare repository
  if grep -q "bare = true" "$git_dir/config" 2>/dev/null; then
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[bare repository]${RESET}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (is a bare repository)" true
    BARE_REPOS+=("$repo_dir")
    return 1
  fi

  # Try to get remote URL from git config
  local remote_url=""
  local first_remote=""
  if git -C "$repo_dir" config --get remote.origin.url &>/dev/null; then
    remote_url=$(git -C "$repo_dir" config --get remote.origin.url)
  elif git -C "$repo_dir" remote | grep -q .; then
    # If origin doesn't exist but other remotes do, use the first one
    first_remote=$(git -C "$repo_dir" remote | head -n 1)
    remote_url=$(git -C "$repo_dir" config --get "remote.$first_remote.url")
    log_message "  NOTE: Using remote '$first_remote' instead of 'origin' for $repo_dir"
  else
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[no remote configured]${RESET}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (no remote configured)" true
    NO_REMOTE_REPOS+=("$repo_dir")
    return 1
  fi

  # Extract host, username, and repository from URL
  local host=""
  local path=""

  # Parse SSH URLs like: git@github.com:username/repo.git
  if [[ "$remote_url" =~ ^git@([^:]+):(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    
    # For SSH URLs, remove .git suffix if present
    path="${path%.git}"

  # Parse HTTPS URLs like: https://github.com/username/repo.git
  elif [[ "$remote_url" =~ ^https?://([^/]+)/(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    
    # For HTTPS URLs, remove .git suffix if present
    path="${path%.git}"

  # Parse Git URLs like: git://github.com/username/repo.git
  elif [[ "$remote_url" =~ ^git://([^/]+)/(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    
    # Remove .git suffix if present
    path="${path%.git}"
  else
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[unrecognized URL format]${RESET}"
    echo -e "     Remote URL: ${remote_url}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (unrecognized remote URL format: $remote_url)" true
    URL_FORMAT_REPOS+=("$repo_dir:$remote_url")
    return 1
  fi

  # Validate host and path
  if [[ -z "$host" || -z "$path" ]]; then
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_display="${BLUE}[${REPO_COUNTER}/${REPOS_FOUND}]${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[parsing error]${RESET}"
    echo -e "     Remote URL: ${remote_url}"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (could not parse remote URL: $remote_url)" true
    PARSING_ERROR_REPOS+=("$repo_dir:$remote_url")
    return 1
  fi

  # Calculate target directory
  local target_dir="$TARGET_BASE/$host/$path"
  
  # Check if source and target are the same (already in the correct location)
  # Remove trailing slashes for comparison to handle case where one has a slash and one doesn't
  local repo_dir_clean="${repo_dir%/}"
  local target_dir_clean="${target_dir%/}"
  if [[ "$repo_dir_clean" == "$target_dir_clean" ]]; then
    # Skip silently - it's already in the right spot, no need to report it
    log_message "SKIP: $repo_dir (already in correct location)" true
    return 1
  fi
  
  # Check for uncommitted changes - this warning is now handled in the formatting code below

  # Check if target directory already exists (and is not the same as source)
  if [[ -d "$target_dir" ]]; then
    local repo_name
    repo_name=$(basename "$repo_dir")
    local counter_raw="[${REPO_COUNTER}/${REPOS_FOUND}]"
    local counter_padded=$(printf "%-8s" "$counter_raw")
    local counter_display="${BLUE}${counter_padded}${RESET}"
    local formatted_relpath=$(format_path "$repo_dir")
    echo -e "${RED}${ICON_SKIP}${RESET} $counter_display ${RED}${BOLD}${formatted_relpath}${RESET} ${RED}[target already exists]${RESET}"
    echo -e "       ->  $(format_path "$target_dir")"
    echo ""
    log_message "${RED}${ICON_SKIP} SKIP:${RESET} $repo_dir (target already exists: $target_dir)" true
    
    # Check if the repo has uncommitted changes
    if ! git -C "$repo_dir" diff --quiet || ! git -C "$repo_dir" diff --cached --quiet; then
      TARGET_EXISTS_DIRTY_REPOS+=("$repo_dir -> $target_dir")
    else
      TARGET_EXISTS_REPOS+=("$repo_dir -> $target_dir")
    fi
    
    return 1
  fi

  # Ensure target parent directory exists
  local target_parent
  target_parent=$(dirname "$target_dir")

  # Format the output with colors and highlighting
  local repo_name
  repo_name=$(basename "$repo_dir")
  local status_msg=""
  local status_icon=""
  local status_color="$CYAN"
  
  # Check for uncommitted changes first to set warning if needed
  if ! git -C "$repo_dir" diff --quiet || ! git -C "$repo_dir" diff --cached --quiet; then
    status_msg=" ${YELLOW}[uncommitted changes]${RESET}"
    status_icon="$ICON_WARNING"
    status_color="$YELLOW"
  fi
  
  # Format paths for display
  local formatted_src
  local formatted_dst
  formatted_src=$(format_path "$repo_dir")
  formatted_dst=$(format_path "$target_dir")
  
  # Print repository information with counter - apply padding directly to counter display
  local counter_raw="[${REPO_COUNTER}/${REPOS_FOUND}]"
  local counter_padded=$(printf "%-8s" "$counter_raw")
  local counter_display="${BLUE}${counter_padded}${RESET}"
  local formatted_relpath=$(format_path "$repo_dir")
  local prefix_spacing=""
  
  # Create a consistent prefix width (with simplified approach)
  if [[ -n "$status_icon" ]]; then
    # For warnings or errors, include icon
    prefix_spacing="${status_color}${status_icon}${RESET} $counter_display"
  else
    # For normal entries, add double space where icon would be
    prefix_spacing="  $counter_display"
  fi
  
  # Ensure prefix is properly aligned 
  echo -e "$prefix_spacing${status_color}${BOLD}${formatted_relpath}${RESET}${status_msg}"
  echo -e "       ->  ${formatted_dst}"
  echo ""
  
  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$target_parent"
    
    # Move the repository
    mv "$repo_dir" "$target_dir"
    
    # Verify the move was successful
    if [[ -d "$target_dir" ]]; then
      log_message "${GREEN}${ICON_SUCCESS} MOVED:${RESET} $repo_dir ${BLUE}→${RESET} $target_dir" true
      return 0
    else
      log_message "${RED}${ICON_SKIP} ERROR:${RESET} Failed to move $repo_dir to $target_dir" true
      return 1
    fi
  else
    log_message "${BLUE}${ICON_MOVE} WOULD MOVE:${RESET} $repo_dir ${BLUE}→${RESET} $target_dir" true
    return 0
  fi
}

# Find all .git directories and process them
log_message "Finding git repositories..."
log_message "Using fd for fast recursive search"

# First count all repositories
echo -e "${BLUE}Finding git repositories...${RESET}"

# Use a POSIX-compatible approach to create our array of git directories
# Find all .git directories and filter them in one go
# The .git/ suffix in the output needs to be removed, and we don't want nested .git directories
git_dirs=$(fd -H -t d "^\.git$" "$SEARCH_DIR" \
  --exclude node_modules \
  --exclude ".Trash" \
  --exclude ".Trashes" \
  --exclude ".TemporaryItems" \
  --exclude ".fseventsd" \
  --exclude ".Spotlight-V100" \
  --exclude ".DocumentRevisions-V100" \
  --exclude '$RECYCLE.BIN' \
  --exclude "System Volume Information" 2>/dev/null | sed 's/\.git\/$//' | sort)


# Count the repositories
REPOS_FOUND=$(echo "$git_dirs" | wc -l | tr -d ' ')
if [[ -z "$git_dirs" || "$REPOS_FOUND" -eq 0 ]]; then
  REPOS_FOUND=0
  echo -e "${RED}No git repositories found. Check if fd is working correctly.${RESET}"
  echo -e "${YELLOW}Try running: fd -H -t d "\.git$" "$SEARCH_DIR" --max-depth 5${RESET}"
fi

echo -e "${GREEN}Found ${BOLD}${REPOS_FOUND}${RESET}${GREEN} git repositories to process${RESET}"

# Process each repository
REPO_COUNTER=0
# Use process substitution to avoid losing variables in pipeline
while IFS= read -r git_dir; do
  # Skip empty lines
  if [[ -z "$git_dir" ]]; then
    continue
  fi
  REPO_COUNTER=$((REPO_COUNTER + 1))
  log_message "Processing repository [${REPO_COUNTER}/${REPOS_FOUND}]: ${git_dir%/.git}" true
  
  # Check if we've hit the limit
  if [[ $REPO_LIMIT -gt 0 ]] && [[ $REPO_COUNTER -gt $REPO_LIMIT ]]; then
    echo -e "${YELLOW}Reached limit of $REPO_LIMIT repositories. Stopping.${RESET}"
    log_message "Reached limit of $REPO_LIMIT repositories. Stopping." true
    break
  fi
  
  if extract_repo_info "$git_dir"; then
    REPOS_MOVED=$((REPOS_MOVED + 1))
  else
    REPOS_SKIPPED=$((REPOS_SKIPPED + 1))
  fi
done < <(echo "$git_dirs")

# Print summary with colors
echo ""
echo -e "${BOLD}Summary:${RESET}"
echo -e "  ${BLUE}Repositories found:${RESET}  $REPOS_FOUND"
echo -e "  ${GREEN}Repositories moved:${RESET}  $REPOS_MOVED"
echo -e "  ${RED}Repositories skipped:${RESET} $REPOS_SKIPPED"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  echo -e "${YELLOW}${BOLD}Dry run completed.${RESET} Re-run without ${CYAN}--dry-run${RESET} to perform the actual reorganization."
else
  echo -e "${GREEN}${BOLD}Reorganization completed.${RESET}"
fi

echo -e "Detailed log available at: ${DIM}$LOG_FILE${RESET}"

# Log summary to file (without colors)
log_message "Summary:" true
log_message "  Repositories found:  $REPOS_FOUND" true
log_message "  Repositories moved:  $REPOS_MOVED" true
log_message "  Repositories skipped: $REPOS_SKIPPED" true

if [[ $DRY_RUN -eq 1 ]]; then
  log_message "Dry run completed. Re-run without --dry-run to perform the actual reorganization." true
else
  log_message "Reorganization completed." true
fi

log_message "Detailed log available at: $LOG_FILE" true

# Print detailed failure report
echo ""
echo -e "${BOLD}Detailed Failure Report:${RESET}"

# Report repositories with no remote configured
if [[ ${#NO_REMOTE_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${RED}Repositories with no remote configured (${#NO_REMOTE_REPOS[@]}):${RESET}"
  for repo in "${NO_REMOTE_REPOS[@]}"; do
    echo -e "  ${BOLD}$repo${RESET}"
  done
fi

# Report repositories where target already exists
if [[ ${#TARGET_EXISTS_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${RED}Repositories where target already exists (${#TARGET_EXISTS_REPOS[@]}):${RESET}"
  for repo_info in "${TARGET_EXISTS_REPOS[@]}"; do
    # Extract source and target paths from stored string
    src_path=$(echo "$repo_info" | cut -d' ' -f1)
    dst_path=$(echo "$repo_info" | cut -d' ' -f3)
    echo -e "  ${BOLD}$src_path -> $dst_path${RESET}"
  done
fi

# Report repositories where target already exists AND source has uncommitted changes
if [[ ${#TARGET_EXISTS_DIRTY_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${YELLOW}Source repositories with uncommitted changes where target exists (${#TARGET_EXISTS_DIRTY_REPOS[@]}):${RESET}"
  for repo_info in "${TARGET_EXISTS_DIRTY_REPOS[@]}"; do
    # Extract source and target paths from stored string
    src_path=$(echo "$repo_info" | cut -d' ' -f1)
    dst_path=$(echo "$repo_info" | cut -d' ' -f3)
    echo -e "  ${BOLD}${YELLOW}$src_path${RESET} -> ${BOLD}$dst_path${RESET}"
  done
fi

# Report repositories with unrecognized URL format
if [[ ${#URL_FORMAT_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${RED}Repositories with unrecognized URL format (${#URL_FORMAT_REPOS[@]}):${RESET}"
  for repo in "${URL_FORMAT_REPOS[@]}"; do
    IFS=":" read -r repo_path remote_url <<< "$repo"
    echo -e "  ${BOLD}$repo_path${RESET}"
    echo -e "    Remote URL: $remote_url"
  done
fi

# Report repositories with URL parsing errors
if [[ ${#PARSING_ERROR_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${RED}Repositories with URL parsing errors (${#PARSING_ERROR_REPOS[@]}):${RESET}"
  for repo in "${PARSING_ERROR_REPOS[@]}"; do
    IFS=":" read -r repo_path remote_url <<< "$repo"
    echo -e "  ${BOLD}$repo_path${RESET}"
    echo -e "    Remote URL: $remote_url"
  done
fi

# Only print these sections if they have entries
if [[ ${#SOURCE_GONE_REPOS[@]} -gt 0 || ${#WORKTREE_REPOS[@]} -gt 0 || ${#SUBMODULE_REPOS[@]} -gt 0 || ${#BARE_REPOS[@]} -gt 0 ]]; then
  echo -e "\n${BOLD}Other skipped repositories:${RESET}"
  
  # Report source gone repositories
  if [[ ${#SOURCE_GONE_REPOS[@]} -gt 0 ]]; then
    echo -e "\n${GRAY}Source no longer exists (${#SOURCE_GONE_REPOS[@]}) - likely moved with parent${RESET}"
  fi
  
  # Report git worktrees
  if [[ ${#WORKTREE_REPOS[@]} -gt 0 ]]; then
    echo -e "\n${GRAY}Git worktrees (${#WORKTREE_REPOS[@]})${RESET}"
  fi
  
  # Report git submodules
  if [[ ${#SUBMODULE_REPOS[@]} -gt 0 ]]; then
    echo -e "\n${GRAY}Git submodules (${#SUBMODULE_REPOS[@]})${RESET}"
  fi
  
  # Report bare repositories
  if [[ ${#BARE_REPOS[@]} -gt 0 ]]; then
    echo -e "\n${GRAY}Bare repositories (${#BARE_REPOS[@]})${RESET}"
  fi
fi