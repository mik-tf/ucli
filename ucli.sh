#!/bin/bash

# ANSI color codes
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
NC=$(printf '\033[0m')
ENV_FILE="$HOME/.ucli_env"

# Logging functions for consistent output formatting
log() {
    echo -e "${GREEN}[UPDATE]${NC} $1"
    sleep 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    sleep 1
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    sleep 1
    exit 1
}


# Help function
show_help() {
  log "Displaying help message"
  printf "\n${GREEN}UCLI - Universal Command Line Interface Tool${NC}\n\n"
  printf "Commands:\n"
  printf "  ${GREEN}install${NC}       Install ucli to /usr/local/bin\n"
  printf "  ${GREEN}uninstall${NC}     Remove ucli from /usr/local/bin\n"
  printf "  ${GREEN}login${NC}         Set GitHub organization\n"
  printf "  ${GREEN}logout${NC}        Unset GitHub organization\n"
  printf "  ${GREEN}list${NC}          List organization repositories\n"
  printf "  ${GREEN}build <name>${NC}  Build a tool from GitHub repository\n"
  printf "  ${GREEN}help${NC}          Show this help message\n\n"
  printf "${YELLOW}Interactive mode: Run 'ucli' without arguments\n\n${NC}"
  printf "Version: 0.0.1\n"
  printf "License: Apache 2.0\n"
  printf "Repository: https://github.com/mik-tf/ucli\n\n"
  read -r -p "${YELLOW}Press ENTER to return to main menu (interactive mode) or exit (command-line mode)...${NC}"
}

# Install script
install() {
  if [[ ! -d "/usr/local/bin" ]]; then
    if sudo mkdir -p /usr/local/bin; then
      log "Directory /usr/local/bin created successfully."
    else
      error "Error creating directory /usr/local/bin."
    fi
  fi
  if sudo cp "$0" /usr/local/bin/ucli && sudo chmod +x /usr/local/bin/ucli; then
      log "ucli installed to /usr/local/bin."
  else
      error "Error installing ucli."
  fi
}

# Uninstall script
uninstall() {
  if [[ -f "/usr/local/bin/ucli" ]]; then
    if sudo rm /usr/local/bin/ucli; then
      log "ucli successfully uninstalled."
    else
      error "Error uninstalling ucli."
    fi
  else
    warn "ucli is not installed in /usr/local/bin."
  fi
}

# Login
login() {
  if [[ -f "$ENV_FILE" ]]; then
    # Try to read the ORG variable, handle potential errors
    if read -r ORG < "$ENV_FILE" && [[ -n "$ORG" ]]; then
      log "Already logged in as $ORG"
      return 0
    else
      warn "Existing $ENV_FILE is corrupted.  Overwriting..."
    fi
  fi

  while true; do
    read -r -p "User/Organization (required): " ORG
    if [[ -z "$ORG" ]]; then
      warn "Organization name cannot be empty."
    else
      # Use printf to ensure proper file writing, even with special characters
      printf "%s\n" "$ORG" > "$ENV_FILE"
      log "Logged in as $ORG"
      return 0
    fi
  done
}

# Check login
check_login() {
  if [[ ! -f "$ENV_FILE" ]]; then
    warn "Please login first using 'ucli login'."
    return 1
  fi

  if ! read -r ORG < "$ENV_FILE" || [[ -z "$ORG" ]]; then
    warn "Error reading or invalid organization in $ENV_FILE. Please login again."
    rm -f "$ENV_FILE" # Remove the corrupted file
    return 1
  fi
  return 0
}

# Logout function
logout() {
  if [[ -f "$ENV_FILE" ]]; then
    rm "$ENV_FILE"
    log "Successfully logged out."
  else
    warn "You are not currently logged in."
  fi
}

# Function to list repositories
list_repos() {
  if ! check_login; then
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    error "curl is required but not installed."
  fi

  log "Fetching repositories for $ORG..."
  local repos=$(curl -s "https://api.github.com/users/${ORG}/repos" |
                grep '"name":' |
                sed -E 's/.*"name": "([^"]+)".*/\1/' |
                grep -v "Apache License 2.0" |
                sort)

  if [[ -z "$repos" ]]; then
    warn "Failed to fetch repository data"
    read -n 1 -s -r -p "Press ENTER to return to main menu..."
    return 1
  fi

  echo "$repos"
  log "Repository list displayed"
  log "Press ENTER to return to main menu..."
  read -r
}

# Function to fetch and run
fetch_and_run() {
  if ! check_login; then
    return 1
  fi

  local repo="$1"
  local org="$ORG"
  local tmpdir="/tmp/ucli/$org/$repo"
  local original_dir=$(pwd)

  if ! mkdir -p "$tmpdir"; then
    error "Error creating temporary directory $tmpdir"
  fi

  log "Cloning repository ${org}/${repo}..."
  cd "$original_dir" || error "Error changing to original directory"

  if ! git clone --depth 1 "https://github.com/$org/$repo.git" "$tmpdir"; then
    error "Error cloning repository ${org}/${repo}"
  fi

  cd "$tmpdir" || { error "Error changing to directory $tmpdir"; }

  log "Running make..."
  if ! make; then
    error "Error executing Makefile in $repo"
  fi

  log "Build successful!"
  rm -rf "$tmpdir"
  cd "$original_dir" || error "Error returning to original directory"
}


# Main function
main() {
  if [[ -z "$1" ]]; then # Interactive mode
    while true; do
      clear
      printf "${GREEN}Welcome to UCLI, the Universal Command Line Interface Tool!${NC}\n\n"
      printf "${YELLOW}Select an option by entering its number or name:${NC}\n\n"
      printf "  1. ${GREEN}login${NC}   - Set your GitHub organization\n"
      printf "  2. ${GREEN}build${NC}   - Build a tool from a GitHub repository\n"
      printf "  3. ${GREEN}list${NC}    - List organization repositories\n"
      printf "  4. ${GREEN}logout${NC}  - Unset your GitHub organization\n"
      printf "  5. ${GREEN}help${NC}    - Show help information\n"
      printf "  6. ${GREEN}exit${NC}    - Exit ucli\n\n"

      read -r -p "Enter your choice: " choice

      case "$choice" in
        1|login) login ;;
        2|build)
          read -r -p "Repository name: " repo
          fetch_and_run "$repo" ;;
        3|list) list_repos ;;
        4|logout) logout ;;
        5|help) show_help ;;
        6|exit) exit 0 ;;
        *) printf "${RED}Invalid choice. Try 'help' for more information.${NC}\n" ;;
      esac
    done
  else # Command-line mode
    case "$1" in
      install) install ;;
      uninstall) uninstall ;;
      login) login ;;
      logout) logout ;;
      list) list_repos ;;
      build) fetch_and_run "$2" ;;
      help) show_help ;;
      *) printf "${RED}Invalid command. Use 'ucli help' for usage information.\n${NC}"; exit 1 ;;
    esac
  fi
}

main "$@"