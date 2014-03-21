#!/bin/bash

# TODO: Abort if not mac


# Key Mapping
# @ Command
# ~ Option
# $ Shift
# ^ Control

###############################################################################
# Microsoft Outlook
###############################################################################
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add "Mark as Done" "^d"
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add "Archive Message" "^a"
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add "Mark as Followup" "^f"
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add "Mark as Todo" "^t"
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add "Mark as Waiting" "^w"