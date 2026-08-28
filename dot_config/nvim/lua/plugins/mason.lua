return {
  {
    "mason-org/mason.nvim",
    -- Prefer native WSL tools; use Mason when no native tool is available.
    opts = { PATH = "append" },
  },
}
