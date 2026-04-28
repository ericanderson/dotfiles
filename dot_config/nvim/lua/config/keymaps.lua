local map = vim.keymap.set

-- Clear search highlight
map("n", "<leader>n", ":nohlsearch<CR>", { silent = true })
map("n", "<leader><space>", ":noh<CR>", { silent = true })

-- Make Ctrl-u and Ctrl-w undoable in insert mode
map("i", "<C-u>", "<C-g>u<C-u>")
map("i", "<C-w>", "<C-g>u<C-w>")

-- Sane regex (very-magic)
map("n", "/", "/\\v")
map("v", "/", "/\\v")

-- j/k respect wrapped lines
map("n", "j", "gj")
map("n", "k", "gk")

-- Strip trailing whitespace
map("n", "<leader>W", [[:%s/\s\+$//<CR>:let @/=""<CR>]], { silent = true })

-- jj escapes insert mode
map("i", "jj", "<ESC>")

-- Window navigation
map("n", "<C-J>", "<C-W><C-J>")
map("n", "<C-K>", "<C-W><C-K>")
map("n", "<C-L>", "<C-W><C-L>")
map("n", "<C-H>", "<C-W><C-H>")
