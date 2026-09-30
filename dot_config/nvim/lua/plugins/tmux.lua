return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    -- Our own herdr-aware <C-hjkl> maps live in config/keymaps.lua. Keep this
    -- plugin only as the provider for TmuxNavigate* fallback commands (used at
    -- split edges when inside tmux, and for <C-\> previous).
    vim.g.tmux_navigator_no_mappings = 1
  end,
}
