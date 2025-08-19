# Nerd Font Icons System

This system provides easy access to Nerd Font icons in your shell scripts and configurations.

Each icon is defined as an exported bash variable with its Unicode escape sequence and displayed as the actual character in the comments for easy reference.

## Files

- `glyphnames.json` - The original JSON file containing all Nerd Font icon definitions
- `generate-nf-icons.ts` - TypeScript script that generates the icons file
- `nf-icons.sh` - The generated bash script with all icons as variables
- `test-icons.sh` - Example script demonstrating icon usage

## Usage

1. Source the icons file in your script:
   ```bash
   source /path/to/bin/nerdfonts/nf-icons.sh
   ```

2. Use icons in your scripts:
   ```bash
   echo "$NF_FA_GITHUB GitHub"
   echo "$NF_DEV_PYTHON Python"
   ```

3. Test available icons:
   ```bash
   ./test-icons.sh
   ```

## Icon Naming Convention

All icon variable names follow the format:

- `NF_` prefix
- Category prefix (FA_, DEV_, COD_, etc.)
- Original name in uppercase with underscores

Examples:
- `fa-github` → `$NF_FA_GITHUB`
- `dev-python` → `$NF_DEV_PYTHON`
- `cod-folder` → `$NF_COD_FOLDER`

## Format Example

The icons are defined in a clean, aligned format with the actual character shown in the comment:

```bash
export NF_FA_GITHUB=$'\U0000f09b'              # 
export NF_DEV_PYTHON=$'\U0000f73c'             # 
export NF_COD_FOLDER=$'\U0000ea83'             # 
```

The script properly handles Unicode characters by using:
- `\uXXXX` format for 4-digit codes
- `\UXXXXXXXX` format (with leading zeros) for longer codes
This ensures proper display in the terminal.

## Regenerating Icons

If you want to update the icons file:

```bash
# TypeScript version (requires Bun)
bun run generate-nf-icons.ts
```

## Common Icon Prefixes

- `FA_` - Font Awesome icons
- `DEV_` - Development/language icons
- `COD_` - VS Code icons
- `MD_` - Material Design icons
- `WEATHER_` - Weather icons
- `CUSTOM_` - Custom icons

## Requirements

- TypeScript generator requires [Bun](https://bun.sh/) to be installed
- The generated bash script has no dependencies