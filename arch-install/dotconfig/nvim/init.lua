vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- Load plugins from the 'plugins' directory
require("lazy").setup("plugins")
require("keymaps")

require('rose-pine').setup({
  variant = 'main', -- 'main', 'moon', 'dawn'
  dark_variant = 'main', -- 'main', 'moon', 'dawn'
  bold_vert_split = false,
  dim_inactive_windows = false,
  extend_builtin_themes = true, -- Enable nvim-tree, telescope, notify etc.
})

-- Set the colorscheme
vim.cmd.colorscheme("rose-pine")

vim.opt.tabstop = 4        -- Number of visual spaces per TAB
vim.opt.shiftwidth = 4     -- Number of spaces to use for autoindent
vim.opt.softtabstop = 4    -- Number of spaces a <Tab> counts for while editing
vim.opt.expandtab = true
