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

require("lazy").setup("plugins")
require("keymaps")

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

if vim.fn.executable('wl-copy') == 1 and vim.fn.executable('wl-paste') == 1 then
  vim.opt.clipboard:append("unnamedplus")
  
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

vim.cmd('hi Normal guibg=none')
vim.cmd('hi NormalFloat guibg=none')
vim.cmd('hi FloatBorder guibg=none')
