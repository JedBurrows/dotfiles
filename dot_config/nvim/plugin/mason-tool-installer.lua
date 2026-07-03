return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  opts = {
    run_on_start = false, auto_update = false,
    ensure_installed = {
      "clangd", "jdtls", "json-lsp", "kotlin-language-server", "marksman",
      "basedpyright", "ruff", "vtsls",              -- verify pyright vs basedpyright for your LazyVim
      "stylua", "prettier", "shfmt", "markdownlint-cli2",
    },
  },
}
