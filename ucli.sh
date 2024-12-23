#!/bin/bash

# ANSI color codes
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
NC=$(printf '\033[0m')

# Help function
show_help() {
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
      printf "${GREEN}Directory /usr/local/bin created successfully.${NC}\n"
    else
      printf "${RED}Error creating directory /usr/local/bin.${NC}\n"
      exit 1
    fi
  fi
  if sudo cp "$0" /usr/local/bin/ucli && sudo chmod +x /usr/local/bin/ucli; then
    printf "${GREEN}ucli installed to /usr/local/bin.${NC}\n"
  else
    printf "${RED}Error installing ucli.${NC}\n"
    exit 1
  fi
}

# Uninstall script
uninstall() {
  if [[ -f "/usr/local/bin/ucli" ]]; then
    if sudo rm /usr/local/bin/ucli; then
      printf "${GREEN}ucli successfully uninstalled.${NC}\n"
    else
      printf "${RED}Error uninstalling ucli.${NC}\n"
      exit 1
    fi
  else
    printf "${YELLOW}ucli is not installed in /usr/local/bin.${NC}\n"
  fi
}

# Function to handle login and store credentials in environment variables
login() {
  until [[ -n "$ORG" ]]; do
    read -r -p "User/Organization (required): " org
    if [[ -z "$org" ]]; then
      printf "${YELLOW}Organization name cannot be empty.${NC}\n"
    else
      export ORG="$org"
      break
    fi
  done
  printf "${GREEN}Logged in as ${YELLOW}$ORG${NC}\n"
}

# Function to handle logout and remove the ORG environment variable
logout() {
  if [[ -z "$ORG" ]]; then
    printf "${YELLOW}You are not currently logged in.${NC}\n"
    return 0
  fi
  unset ORG
  printf "${GREEN}Successfully logged out.${NC}\n"
}

# Function to list repositories
list_repos() {
  if [[ -z "$ORG" ]]; then
    printf "${RED}Please login first using 'ucli login'.${NC}\n"
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    printf "${RED}Error: curl is required but not installed.${NC}\n"
    exit 1
  fi

  printf "\n${YELLOW}Fetching repositories for ${ORG}...${NC}\n\n"
  local repos=$(curl -s "https://api.github.com/users/${ORG}/repos" | 
                grep '"name":' | 
                sed -E 's/.*"name": "([^"]+)".*/\1/' |
                grep -v "Apache License 2.0" |
                sort)
  
  if [[ -z "$repos" ]]; then
    printf "${RED}Error: Failed to fetch repository data${NC}\n"
    read -n 1 -s -r -p "Press ENTER to return to main menu..."
    return 1
  fi

  echo "$repos"
  printf "\n${YELLOW}Press ENTER to return to main menu...${NC}"
  read -r
}

fetch_and_run() {
  local org="$ORG"
  local repo="$1"
  local tmpdir="/tmp/code/github.com/$org/$repo"
  local original_dir=$(pwd)

  if [[ -z "$org" ]]; then
    printf "${RED}Please login first using 'ucli login'.${NC}\n"
    return 1
  fi

  if ! mkdir -p "$tmpdir"; then
    printf "${RED}Error creating temporary directory $tmpdir: $?${NC}\n"
    exit 1
  fi

  printf "${YELLOW}Cloning repository...${NC}\n"
  cd "$original_dir"
  if ! git clone --depth 1 "https://github.com/$org/$repo.git" "$tmpdir"; then
    printf "${RED}Error cloning repository $repo: $?${NC}\n"
    rm -rf "$tmpdir"
    exit 1
  fi

  cd "$tmpdir" || { printf "${RED}Error changing to directory $tmpdir: $?${NC}\n"; exit 1; }

  printf "${YELLOW}Running make...${NC}\n"
  if ! make; then
    printf "${RED}Error executing Makefile in $repo: $?${NC}\n"
    rm -rf "$tmpdir"
    exit 1
  fi

  printf "${GREEN}Build successful!${NC}\n"
  sleep 2 # Added 2-second sleep
  rm -rf "$tmpdir"
  cd "$original_dir"
}

# Main interactive loop or command-line execution
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
      *) printf "${RED}Invalid command. Use 'ucli help' for usage information.${NC}\n"; exit 1 ;;
    esac
  fi
}

main "$@"