local opt = vim.opt

-- General
opt.title = true
opt.history = 256
opt.writebackup = false
opt.backup = false
opt.hidden = true
opt.encoding = "utf-8"
opt.scrolloff = 3

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- UI
opt.number = true
opt.ruler = true
opt.showmode = false
opt.laststatus = 2
opt.splitbelow = true
opt.splitright = true
opt.wildmenu = true
opt.wildmode = "list:longest"
opt.wildignore:append({ "*.swp", "*.bak", "*.class", "node_modules/**" })

-- Editing
opt.smarttab = true
opt.autoindent = true
opt.backspace = { "indent", "eol", "start" }

-- Mapping timeouts
opt.timeoutlen = 300
opt.ttimeoutlen = 50

-- Backups outside the working directory
local backup_dirs = {
  vim.fn.expand("$HOME/.vim-tmp"),
  vim.fn.expand("$HOME/.tmp"),
  vim.fn.expand("$HOME/tmp"),
  "/var/tmp",
  "/tmp",
}
opt.backupdir = backup_dirs
opt.directory = backup_dirs

-- System clipboard. Neovim 0.10+ auto-uses OSC52 over SSH.
opt.clipboard = "unnamedplus"

-- Leader (set before plugin keys are registered)
vim.g.mapleader = ","
vim.g.maplocalleader = ","
