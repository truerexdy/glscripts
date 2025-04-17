-- lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "pylsp" }, -- Make sure your desired LS is here
    })
    local lspconfig = require("lspconfig")
    lspconfig.pylsp.setup({}) -- This line is crucial
  end,
}
