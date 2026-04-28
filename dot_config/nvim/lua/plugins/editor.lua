return {
  -- Surround text objects (cs, ds, ys)
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- gc / gcc commenting
  { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },

  -- Multi-cursor (Ctrl-N to start, Ctrl-Down/Up to add)
  { "mg979/vim-visual-multi", event = "VeryLazy" },

  -- Ansible
  {
    "pearofducks/ansible-vim",
    ft = { "ansible", "yaml.ansible" },
    init = function()
      vim.g.ansible_name_highlight = "d"
      vim.g.ansible_extra_keywords_highlight = 1
    end,
  },
}
