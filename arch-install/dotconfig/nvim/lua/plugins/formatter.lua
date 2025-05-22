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
      format_on_save = {
        enabled = true,
        require_lsps = false,
      },
    })
  end,
}
