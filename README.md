<h1> ucli: Universal Command Line Interface Tool </h1>

<h2>Table of Contents</h2>

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Interactive Mode](#interactive-mode)
  - [Command-Line Mode](#command-line-mode)
- [Prerequisites](#prerequisites)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

`ucli` is a bash script designed to simplify the process of building tools from GitHub repositories. It provides an interactive menu and command-line interface for login, repository listing (currently a placeholder), and building tools.  It requires `git` and `make` to be installed on the system.

## Features

* **Interactive Mode:**  A user-friendly menu for easy navigation and tool building.
* **Command-Line Mode:** Allows execution of specific commands like installation, login, repository listing, and building a specific repository.
* **GitHub Integration:**  Clones repositories from GitHub (requires a `makefile` in the repository root).
* **Error Handling:** Includes robust error handling and informative messages.
* **Color-Coded Output:** Uses ANSI color codes for improved readability.


## Installation

To install `ucli`, run the following command:

```bash
git clone https://github.com/mik-tf/ucli
cd ucli.sh
bash ucli.sh install
```

This will copy the script to `/usr/local/bin` and make it executable.  You can then run it from anywhere in your system.

## Usage

### Interactive Mode

Run `ucli` without any arguments to enter the interactive mode.  You will be presented with a menu to login, list repositories (currently unavailable), build a tool, or exit.

### Command-Line Mode

`ucli` supports several command-line options:

* `ucli install`: Installs `ucli` to `/usr/local/bin`.
* `ucli login`: Logs in to your GitHub organization, storing the organization name in an environment variable.
* `ucli list`: Lists repositories from your GitHub organization (currently a placeholder; does not actually perform an API call).
* `ucli repo <repo_name>`: Clones the specified repository, runs `make`, and (optionally) cleans up.  Requires being logged in first (`ucli login`).


**Example:** To build a tool from the repository `my-org/my-tool`, you would first log in:

```bash
ucli login
```

Then, build the tool:

```bash
ucli repo my-org/my-tool
```

## Prerequisites

*   `bash` (should be present on most Unix-like systems)
*   `git`
*   `make`

To download the prerequisites:

```
sudo apt install -y git make
```

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This work is under the [Apache 2.0 license](./LICENSE).