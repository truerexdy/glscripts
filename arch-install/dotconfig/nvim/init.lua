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

vim.opt.tabstop = 4        -- Number of visual spaces per TAB
vim.opt.shiftwidth = 4     -- Number of spaces to use for autoindent
vim.opt.softtabstop = 4    -- Number of spaces a <Tab> counts for while editing
vim.opt.expandtab = true

-- wl-clipboard setup for Wayland
if vim.fn.executable('wl-copy') == 1 and vim.fn.executable('wl-paste') == 1 then
  -- Set clipboard to use wl-copy and wl-paste
  vim.opt.clipboard:append("unnamedplus")
  
  -- Override the default clipboard provider
  vim.g.clipboard = {
    name = 'wl-clipboard',
    copy = {
      ['+'] = 'wl-copy --type text/plain',
      ['*'] = 'wl-copy --primary --type text/plain',
    },
    paste = {
      ['+'] = 'wl-paste --no-newline',
      ['*'] = 'wl-paste --primary --no-newline',
    },
    cache_enabled = 1,
  }
end
