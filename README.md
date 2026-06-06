# dotfiles

Managed with [chezmoi](https://chezmoi.io). Arch Linux / [Omarchy](https://omakub.org/omarchy) (Hyprland).

## Bootstrap a new machine

```sh
# 1. Install chezmoi and pull the dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JedBurrows

# 2. Install TPM (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 3. Install tmux plugins non-interactively
~/.tmux/plugins/tpm/bin/install_plugins

# 4. Open nvim once to let lazy.nvim install plugins
nvim --headless "+Lazy! sync" +qa
```

## Per-machine tmux accent colour

`dot_config/tmux/tmux.conf.tmpl` picks an accent based on hostname:

| Hostname | Accent | Colour |
|---|---|---|
| `baldur` (home) | purple | `#d3869b` |
| `WORK_HOSTNAME_TODO` | blue | `#83a598` |
| homelab servers (example) | red | `#fb4934` |

**To add a new machine:** edit `dot_config/tmux/tmux.conf.tmpl` and add a line
in the hostname block at the top, then `chezmoi apply` on that machine.

## Day-to-day

```sh
chezmoi diff          # preview what would change
chezmoi apply         # apply source → home
chezmoi add <file>    # bring a new file under management
chezmoi cd            # open a shell in the source repo
```

## What's managed

- Shell: `.bashrc`, `.gitconfig`
- Terminal: alacritty, tmux (templated)
- Desktop: Hyprland, Waybar, Mako, Walker, SwayOSD, UWSM
- Editor: full Neovim / LazyVim config
- Tools: btop, fastfetch, lazygit, lazydocker, mise, fontconfig
