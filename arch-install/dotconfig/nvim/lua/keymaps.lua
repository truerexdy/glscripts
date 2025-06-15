local telescope = require('telescope')

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>,', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<C-b>', ':Neotree filesystem toggle<CR>', { noremap = true, silent = true })
