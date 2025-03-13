# 🤖 Rules for AI
<img src="https://img.shields.io/badge/LICENSE-MIT-green">

Documentation ([English](https://github.com/hashiiiii/rules-for-ai/blob/main/README.md), [日本語](https://github.com/hashiiiii/rules-for-ai/blob/main/README_JA.md))

## 📋 Overview

This is a ruleset to enhance AI assistants integrated in Windsurf and Cursor.
For global settings, use the predefined windsurf: global_rules.md / cursor: global_rules.mdc.
For workspace-specific settings, use windsurf: .windsurfrules / cursor: project_rules.mdc.
These are automatically updated through interactive dialogue with the AI assistant.

> [!WARNING]
>
> windsurf
> - global: global_rules.md
> - local: .windsurfrules
> - docs: https://docs.codeium.com/windsurf/memories#windsurfrules
>
> cursor
> - global: global_rules.mdc
> - local: project_rules.mdc
> - docs: https://docs.cursor.com/context/rules-for-ai
>

## ✨ Key Features

- 🔄 **Interactive Setup**: Interactively tune .windsurfrules / project_rules.mdc
- 📝 **High-Quality Common Configuration Files**: Pre-defined high-quality global_rules.md / global_rules.mdc
- ⚡ **Task-Oriented Shortcuts**: Shortcuts that can be used universally for each task

## 🚀 Quick Start

1. Clone the repository:
```bash
git clone https://github.com/hashiiiii/rules-for-ai.git
```

2. Open any workspace in your IDE and set up the rules files:
   - `.windsurfrules` / `global_rules.md` - For Windsurf IDE
   - `project_rules.mdc` / `global_rules.mdc` - For Cursor IDE

> [!IMPORTANT]
>
> If global settings are sufficient, migration steps are not necessary.
>

3. Run the setup command
   - Execute the `/setup` command

4. Run the save command
   - Execute the `/store` command

## 🔍 Available Shortcuts

- `/setup`   : Start the setup process
- `/adjust`  : Fine-tune the current workspace configuration file
- `/store`   : Update the file based on the answers obtained through the setup process
- `/plan`    : Create a detailed work plan
- `/debug`   : Systematic debugging approach
- `/review`  : Code quality review
- `/refactor`: Improve readability and maintainability
- `/optimize`: Performance optimization suggestions
- `/test`    : Testing strategy
- `/doc`     : Documentation assistance
- `/arch`    : Architecture design
- `/cmt`     : Code comments
- `/mvp`     : Build an MVP (Minimum Viable Product)
- `/help`    : Display available shortcuts

## 📄 License

This project is provided under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
