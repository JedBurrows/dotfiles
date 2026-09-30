-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Seamless <C-hjkl> navigation between Neovim splits and herdr panes.
-- Ported inline from the vim-herdr-navigation plugin's editor/nvim.lua so it
-- lives in version control (the installed plugin path is commit-hashed and
-- changes on update). Move within Neovim splits; at a split edge, hand off to
-- herdr so focus crosses into the neighbouring pane (tmux/wincmd fallback when
-- not in herdr). These must live here (not a plugin spec / after/plugin) so
-- they run in LazyVim's VeryLazy handler, after LazyVim's own <C-hjkl>
-- defaults, and win the keymap battle.
local function herdr_nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  -- At a split edge: cross into the surrounding multiplexer.
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    -- Target this pane explicitly: --current resolves to the server's globally
    -- focused pane, which is not necessarily the one we are in.
    vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--pane", vim.env.HERDR_PANE_ID })
  elseif vim.env.TMUX and vim.env.TMUX ~= "" then
    local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
    pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
  end
end

for _, m in ipairs({
  { "<C-h>", "h", "left" },
  { "<C-j>", "j", "down" },
  { "<C-k>", "k", "up" },
  { "<C-l>", "l", "right" },
}) do
  vim.keymap.set("n", m[1], function()
    herdr_nav(m[2], m[3])
  end, { silent = true, desc = "Navigate " .. m[3] .. " (vim/herdr)" })
end

-- Previous pane/window: no herdr equivalent, keep tmux/wincmd fallback.
vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { silent = true })
