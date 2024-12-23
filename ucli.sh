#!/bin/bash

# ANSI color codes
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
NC=$(printf '\033[0m')

# Install script
install() {
  if [[ ! -d "/usr/local/bin" ]]; then
    if sudo mkdir -p /usr/local/bin; then
      printf "${GREEN}Directory /usr/local/bin created successfully.${NC}\n"
      sleep 1 # Pause to see the message
    else
      printf "${RED}Error creating directory /usr/local/bin.${NC}\n"
      exit 1
    fi
  fi
  if sudo cp "$0" /usr/local/bin/ucli && sudo chmod +x /usr/local/bin/ucli; then
    printf "${GREEN}ucli installed to /usr/local/bin.${NC}\n"
    sleep 1 # Pause to see the message
  else
    printf "${RED}Error installing ucli.${NC}\n"
    exit 1
  fi
}

# Function to handle login and store credentials in environment variables
login() {
  until [[ -n "$ORG" ]]; do
    read -r -p "User/Organization (required): " org
    if [[ -z "$org" ]]; then
      printf "${YELLOW}Organization name cannot be empty.${NC}\n"
      sleep 1 # Pause to see the message
    else
      export ORG="$org"
      break # Exit the loop once valid input is received.
    fi
  done
  printf "${GREEN}Logged in as ${YELLOW}$ORG${NC}\n"
  sleep 1 # Pause to see the message
}

# Function to handle logout and remove the ORG environment variable
logout() {
  if [[ -z "$ORG" ]]; then
    printf "${YELLOW}You are not currently logged in.${NC}\n"
    sleep 1
    return 0
  fi
  unset ORG
  printf "${GREEN}Successfully logged out.${NC}\n"
  sleep 1
}


fetch_and_run() {
  local org="$ORG"
  local repo="$1"
  local tmpdir="/tmp/code/github.com/$org/$repo"
  local original_dir=$(pwd) # Store the original working directory

  if [[ -z "$org" ]]; then
    printf "${RED}Please login first using 'ucli login'.${NC}\n"
    sleep 1
    return 1
  fi

  if ! mkdir -p "$tmpdir"; then
    printf "${RED}Error creating temporary directory $tmpdir: $?${NC}\n"
    exit 1
  fi

  printf "${YELLOW}Cloning repository...${NC}\n"
  cd "$original_dir"  # Return to the original directory before cloning
  if ! git clone --depth 1 "https://github.com/$org/$repo.git" "$tmpdir"; then
    printf "${RED}Error cloning repository $repo: $?${NC}\n"
    rm -rf "$tmpdir"
    exit 1
  fi
  sleep 1 #Pause to show cloning progress.

  cd "$tmpdir" || { printf "${RED}Error changing to directory $tmpdir: $?${NC}\n"; exit 1; }

  printf "${YELLOW}Running make...${NC}\n"
  if ! make; then
    printf "${RED}Error executing Makefile in $repo: $?${NC}\n"
    rm -rf "$tmpdir"
    exit 1
  fi
  sleep 1 #Pause to show make progress.

  printf "${GREEN}Build successful!${NC}\n"
  sleep 1 # Pause to see the success message
  rm -rf "$tmpdir"
  cd "$original_dir" # Return to the original directory
}


# Main interactive loop or command-line execution
main() {
  if [[ -z "$1" ]]; then # Interactive mode
    while true; do
      clear
      printf "${GREEN}Welcome to UCLI, the Universal Command Line Interface Tool!${NC}\n\n"
      printf "${YELLOW}Select an option by entering its number:${NC}\n\n"
      printf "  1. ${GREEN}Set your GitHub organization${NC}\n"
      printf "  2. ${GREEN}Build a tool from a GitHub repository${NC}\n"
      printf "  3. ${GREEN}Unset your GitHub organization${NC}\n"
      printf "  4. ${GREEN}Exit ucli${NC}\n\n"

      read -r -p "Enter your choice (1-4): " choice

      case "$choice" in
        1) login ;;
        2)
          read -r -p "Repository name: " repo
          fetch_and_run "$repo" ;;
        3) logout ;;
        4) exit 0 ;;
        *) printf "${RED}Invalid choice.${NC}\n"; sleep 1 ;;
      esac
    done
  else # Command-line mode
    case "$1" in
      install) install ;;
      login) login ;;
      logout) logout ;;
      repo) fetch_and_run "$2" ;;
      *) printf "${RED}Usage: ucli [install | login | logout | repo <repo_name> ]${NC}\n"; exit 1 ;;
    esac
  fi
}

main "$@"