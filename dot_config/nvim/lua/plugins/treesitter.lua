return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- master is the legacy stable branch with the configs API. main has a
    -- new (incompatible) API that this config doesn't use.
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash", "c", "diff", "go", "html", "javascript", "json", "lua",
        "markdown", "markdown_inline", "python", "query", "regex", "rust",
        "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
