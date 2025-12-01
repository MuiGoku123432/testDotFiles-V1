-- Make editor respect terminal transparency in Ghostty
return {
  -- If you use any of these themes, enable their built-in transparent mode
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { transparent_background = true },
  },
  {
    "ellisonleao/gruvbox.nvim",
    opts = { transparent_mode = true },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = { disable_background = true, disable_float_background = true },
  },
  {
    "rebelot/kanagawa.nvim",
    opts = { transparent = true },
  },

  -- After ANY colorscheme loads, nuke background on key UI groups
  {
    -- tiny helper spec to run our highlight fixes late
    "lazyvim.nvim",
    optional = true,
    init = function()
      local function set_transparent()
        local groups = {
          "Normal", "NormalNC", "NormalFloat", "SignColumn",
          "MsgArea", "FloatBorder", "TelescopeNormal", "TelescopeBorder",
          "NeoTreeNormal", "NeoTreeNormalNC", "NvimTreeNormal", "NvimTreeNormalNC",
          "Pmenu", "PmenuSel", "CmpNormal", "CmpBorder", "LspInfoBorder",
          "WhichKeyFloat", "NoicePopup", "NoiceCmdlinePopup",
          "EndOfBuffer",
        }
        for _, g in ipairs(groups) do
          pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
        end
      end

      -- run on startup and whenever the scheme changes
      vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
        callback = set_transparent,
        desc = "Force transparent background to respect terminal",
      })

      -- optional: keep popups fully opaque/solid if you prefer
      -- vim.opt.pumblend = 0
      -- vim.opt.winblend = 0
    end,
  },
}
