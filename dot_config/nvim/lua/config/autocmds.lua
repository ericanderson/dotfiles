local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Strip trailing whitespace on save (preserves cursor + view)
autocmd("BufWritePre", {
  group = augroup("StripTrailingWhitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

local ft = augroup("Filetypes", { clear = true })

-- Ruby-ish files without obvious extensions
autocmd({ "BufRead", "BufNewFile" }, {
  group = ft,
  pattern = { "Vagrantfile", "Gemfile", "Rakefile", "Capfile", "*.rake", "config.ru" },
  command = "set ft=ruby",
})

-- Markdown variants
autocmd({ "BufRead", "BufNewFile" }, {
  group = ft,
  pattern = { "*.md", "*.mkd", "*.markdown" },
  command = "set ft=markdown",
})

-- 2-space indent for ruby/yaml
autocmd("FileType", {
  group = ft,
  pattern = { "ruby", "eruby", "yaml" },
  callback = function()
    vim.opt_local.autoindent = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- CoffeeScript
autocmd({ "BufNewFile", "BufRead" }, {
  group = ft,
  pattern = "*.coffee",
  callback = function()
    vim.opt_local.autoindent = true
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})
