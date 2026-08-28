-- Prefer native Linux tools to inherited Windows shims when running under WSL.
local cargo_bin = vim.fn.expand("~/.cargo/bin")
if vim.fn.has("wsl") == 1 and vim.uv.fs_stat(cargo_bin) then
  vim.env.PATH = cargo_bin .. ":" .. (vim.env.PATH or "")
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
