#!/usr/bin/env bun
/**
 * Nerd Font Icons Generator
 * 
 * This script processes the glyphnames.json file from Nerd Fonts and generates
 * a bash-compatible output file with icons formatted as an array.
 * 
 * - Organizes icons by their prefixes (fa-, dev-, cod-, etc.)
 * - Converts variable names from kebab-case to SCREAMING_SNAKE_CASE
 * - Formats each line with proper alignment
 * - Adds comments with the original icon name
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

// Configuration
const SOURCE_FILE = resolve('../../dot_config/nerdfonts/glyphnames.json');
const TARGET_FILE = resolve('./nf-icons.sh');

// Type definitions
type IconData = {
  char: string;
  code: string;
};

type IconsDict = {
  METADATA: {
    version: string;
    date: string;
    [key: string]: string;
  };
  [key: string]: IconData | { [key: string]: string };
};

/**
 * Converts kebab-case to SCREAMING_SNAKE_CASE
 */
function toScreamingSnakeCase(str: string): string {
  return str.replace(/-/g, '_').toUpperCase();
}

/**
 * Groups icons by their prefix (e.g., 'fa-', 'cod-', 'dev-')
 */
function groupIconsByPrefix(icons: Record<string, IconData>): Record<string, Record<string, IconData>> {
  const groups: Record<string, Record<string, IconData>> = {};
  
  for (const [key, value] of Object.entries(icons)) {
    if (typeof value !== 'object' || !('char' in value) || !('code' in value)) continue;
    
    const match = key.match(/^([a-z]+)-(.+)$/);
    if (match) {
      const [, prefix, name] = match;
      if (!groups[prefix]) {
        groups[prefix] = {};
      }
      groups[prefix][name] = value;
    } else {
      // For icons without a prefix
      if (!groups['custom']) {
        groups['custom'] = {};
      }
      groups['custom'][key] = value;
    }
  }
  
  return groups;
}

/**
 * Main function
 */
async function main() {
  console.log('Reading source file...');
  const data = JSON.parse(readFileSync(SOURCE_FILE, 'utf-8')) as IconsDict;
  
  console.log('Processing icons...');
  const { METADATA, ...icons } = data;
  const iconGroups = groupIconsByPrefix(icons as Record<string, IconData>);
  
  // Calculate the maximum length for alignment
  let maxVarNameLength = 0;
  for (const group of Object.values(iconGroups)) {
    for (const key of Object.keys(group)) {
      const varName = toScreamingSnakeCase(`${key}`);
      maxVarNameLength = Math.max(maxVarNameLength, varName.length);
    }
  }
  
  // Generate the output
  let output = `#!/usr/bin/env bash
# Nerd Font Icons
# Generated from Nerd Fonts v${METADATA.version} on ${METADATA.date}
# https://www.nerdfonts.com

# Set locale for proper character display
export LC_ALL=en_US.UTF-8

# Direct icon definitions as variables
`;
  
  // Process each group
  for (const [prefix, group] of Object.entries(iconGroups)) {
    output += `    # ${prefix.toUpperCase()} Icons\n`;
    
    for (const [key, value] of Object.entries(group)) {
      const varName = toScreamingSnakeCase(`${prefix}_${key}`);
      // Handle Unicode characters properly based on code length
      let unicodeValue;
      if (value.code.length <= 4) {
        unicodeValue = `\\u${value.code}`;
      } else {
        // For codes longer than 4 digits, use the uppercase \U and ensure 8 digits
        // by padding with leading zeros if needed
        unicodeValue = `\\U${value.code.padStart(8, '0')}`;
      }
      const rawChar = value.char; // Use the pre-existing character directly from JSON
      
      // Pad the variable name for alignment
      const paddedVarName = varName.padEnd(maxVarNameLength + 4);
      
      output += `export NF_${varName}=$'${unicodeValue}'              # ${rawChar}\n`;
    }
    
    output += '\n';
  }
  
  output += '\n# End of Nerd Font icons';
  
  console.log('Writing output file...');
  writeFileSync(TARGET_FILE, output, 'utf-8');
  
  console.log('Done!');
}

main().catch(console.error);