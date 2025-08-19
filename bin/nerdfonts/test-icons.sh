#!/usr/bin/env bash

# Source the icons file
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/nf-icons.sh"

# Print a header
echo ""
echo "=========================================="
echo "   Nerd Font Icons Test Script"
echo "=========================================="
echo ""

# Test a few Font Awesome icons
echo "Font Awesome icons:"
echo " $NF_FA_GITHUB GitHub (NF_FA_GITHUB)"
echo " $NF_FA_HEART Heart (NF_FA_HEART)"
echo " $NF_FA_STAR Star (NF_FA_STAR)"
echo " $NF_FA_CHECK Check (NF_FA_CHECK)"
echo ""

# Test a few Dev icons
echo "Dev icons:"
echo " $NF_DEV_PYTHON Python (NF_DEV_PYTHON)"
echo " $NF_DEV_NODEJS Node.js (NF_DEV_NODEJS)"
echo " $NF_DEV_HTML5 HTML5 (NF_DEV_HTML5)"
echo " $NF_DEV_CSS3 CSS3 (NF_DEV_CSS3)"
echo ""

# Test a few VS Code icons
echo "VS Code icons:"
echo " $NF_COD_ACCOUNT Account (NF_COD_ACCOUNT)"
echo " $NF_COD_FOLDER Folder (NF_COD_FOLDER)"
echo " $NF_COD_FILE File (NF_COD_FILE)"
echo " $NF_COD_TERMINAL Terminal (NF_COD_TERMINAL)"
echo ""

# Test a few Material Design icons
echo "Material Design icons:"
echo " $NF_MD_ALERT Alert (NF_MD_ALERT)"
echo " $NF_MD_CHECK Check (NF_MD_CHECK)"
echo " $NF_MD_CLOSE Close (NF_MD_CLOSE)"
echo " $NF_MD_SETTINGS_HELPER Settings Helper (NF_MD_SETTINGS_HELPER)"
echo ""

echo "=========================================="
echo ""