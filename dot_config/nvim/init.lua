-- Order matters: options/keymaps before plugins so they're set when plugins load.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
