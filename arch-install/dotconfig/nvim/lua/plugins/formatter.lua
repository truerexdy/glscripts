-- lua/plugins/formatter.lua
return {
  "mhartington/formatter.nvim",
  config = function()
    require("formatter").setup({
      filetype = {
        lua = {
          function()
            return {
              exe = "stylua",
              args = {}
            }
          end
        },
        python = {
          function()
            return {
              exe = "black",
              args = {}
            }
          end
        },
        javascript = {
          function()
            return {
              exe = "prettier",
              args = {}
            }
          end
        },
        typescript = {
          function()
            return {
              exe = "prettier",
              args = {}
            }
          end
        },
        go = {
          function()
            return {
              exe = "goimports",
              args = {}
            }
          end
        },
      },
      -- Add this section to enable formatting on save for all configured filetypes
      format_on_save = {
        enabled = true,
        -- Specify if you want to format only when the last write was successful
        -- by default it will format always
        require_lsps = false, -- Only format if an LSP client is attached.
      },
    })
  end,
}
