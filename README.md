# 🤖 Rules for AI

Documentation ([English](https://github.com/hashiiiii/rules-for-ai/blob/main/README.md), [日本語](https://github.com/hashiiiii/rules-for-ai/blob/main/README_JA.md))

## 📋 Overview

A collection of rules and guidelines to enhance AI assistant interactions for developers. Designed for use with Windsurf, Cursor, and other AI-powered coding assistants. The global settings use predefined global_rules.md, and workspace-specific customizations are set in .windsurfrules / .cursorrules. These are automatically updated through interactive conversations with the AI assistant.

## ✨ Key Features

- 🔄 **Interactive Setup**: Interactively tune .windsurfrules / .cursorrules
- 📝 **High-Quality Common Configuration**: Predefined high-quality global_rules.md
- ⚡ **Task-Oriented Shortcuts**: Pre-defined aliases for common development tasks

## 🚀 Quick Start

1. Clone this repository:
```bash
git clone https://github.com/hashiiiii/rules-for-ai.git
```

2. Open any workspace in your IDE and set up the rule files:
   - `.windsurfrules` / `global_rules.md` - For Windsurf IDE
   - `.cursorrules` / `global_rules.md` - For Cursor IDE
   
3. Run the setup command:
   - Note: If global_rules.md is sufficient for your needs, the following steps are not necessary
   - Enter `/setup` command in write mode

4. Verify that .windsurfrules / .cursorrules have been updated:
   - If no updates occur, ask the AI assistant to update them in write mode

## ⚙️ Setting Up .windsurfrules / .cursorrules

The `.windsurfrules` / `.cursorrules` files provide an interactive setup process to customize the AI assistant's behavior to your specific needs.

## 🔧 Customization

After completing the initial `/setup`, you can further adjust your settings.
Use `/adjust` to fine-tune the current configuration.

## 🔍 Available Shortcuts

The following shortcuts are available:

- `/setup`   : Starts the setup process
- `/adjust`  : Fine-tunes the current configuration
- `/plan`    : Generate detailed work plans
- `/debug`   : Systematic debugging approach
- `/review`  : Code quality review
- `/refactor`: Readability and maintainability improvements
- `/optimize`: Performance optimization suggestions
- `/test`    : Testing strategies
- `/doc`     : Documentation assistance
- `/arch`    : Architecture design
- `/cmt`     : Code commenting
- `/mvp`     : Build a Minimum Viable Product
- `/help`    : Display available shortcuts

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
