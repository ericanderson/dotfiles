return {
  -- Distraction-free writing (replaces goyo)
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = { { "<leader>z", "<cmd>ZenMode<CR>", desc = "Zen mode" } },
    opts = {},
  },

  -- Dim inactive code (replaces limelight)
  {
    "folke/twilight.nvim",
    cmd = { "Twilight", "TwilightEnable" },
    opts = {},
  },
}
