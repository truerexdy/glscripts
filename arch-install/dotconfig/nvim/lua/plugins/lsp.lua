
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp", -- Needed for capabilities
  },
  config = function()
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = {
        "clangd",         -- C/C++
        "pylsp",          -- Python
        "gopls",          -- Go
        "rust_analyzer",  -- Rust
        "jdtls",          -- Java
        "html",           -- HTML
        "ts_ls",       -- JavaScript/TypeScript
        "lua_ls",         -- Lua
        "jsonls",         -- JSON
        "yamlls",         -- YAML
      },
    })

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Set up servers
    local servers = {
      clangd = {},
      pylsp = {},
      gopls = {},
      rust_analyzer = {},
      jdtls = {},
      html = {},
      ts_ls= {},
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      },
      jsonls = {},
      yamlls = {},
    }

    for server, config in pairs(servers) do
      config.capabilities = capabilities
      lspconfig[server].setup(config)
    end
  end,
}
