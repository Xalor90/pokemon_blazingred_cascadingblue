# GBA Framework

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This is a C++ framework for developing Game Boy Advance (GBA) games using Object-Oriented Programming (OOP) principles. The framework provides core functionality for graphics, input handling, sound, and system initialization, making it easier to develop and maintain GBA games.

## Purpose

The purpose of this framework is to provide a reusable and organized codebase for GBA development. By using this framework, you can focus on game-specific logic while leveraging the core functionalities provided by the framework. This approach promotes code reuse and maintainability across multiple GBA projects.

## Features

I will be updating this list as I add new functionality to the framework.

## Getting Started

### Installation and Setup

1. Fork the Repository
   - Navigate to the (original repository)[https://github.com/Xalor90/gba-framework] on GitHub.
   - Click the Fork button in the upper-right corner.
   - Name your fork of the repo to your desired game/project name.
2. Clone Your Repository
   - Clone your newly forked repository to your local machine. Open your terminal (or Git Bash) and run:
      - `git clone https://github.com/your-username/your-project-name.git`
      - Replace your-username and your-project-name with your actual GitHub username and the repository name you set.
3. Run the Installation Script
   - Windows:
      - Open PowerShell in the root directory of your cloned repository.
      - To view available installation options, run:
         - `.\install.ps1 -help`
      - To install the project with assembly support enabled, run:
         - `.\install.ps1 -WithAssembly`
         - Running this command will set up your project accordingly, including creating a local configuration override (e.g., config.local.mk) with assembly support enabled.
   - Mac:
      - WIP: Installation instructions to be added at a later date.
   - Linux:
      - WIP: Installation instructions to be added at a later date.

### Usage

Include the necessary headers from the framework and initialize the core components in your project. Examples to be added later.

### Documentation

Documentation to be updated as new components are added to the framework.

### Contributing

Contributions are welcome! If you have suggestions for improvements or new features, feel free to open an issue or submit a pull request.

### License

This project is licensed under the GPL v3 License. See the [LICENSE](LICENSE) file for details.

### Acknowledgments

Inspired by various GBA development resources and communities, but primarily [Pret](https://github.com/pret). I will try to keep this section updated as I build out the framework.