# Forest Canopy

Colors match `lua/themes/rose.lua`. Diff backgrounds match current 75% blend.

## Ghostty

Add to Ghostty config:

```ini
config-file = /Users/jfdenton/.config/nvim/external/forest-canopy.ghostty
```

Place after existing color settings, then reload Ghostty config.

## Git delta

Add to `~/.gitconfig`:

```gitconfig
[include]
    path = /Users/jfdenton/.config/nvim/external/forest-canopy.gitconfig

[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    features = forest-canopy
```

Append `forest-canopy` to existing `features` if needed. Existing `[delta]`
color options override feature colors; remove conflicting options.

Delta uses `ansi` syntax highlighting with Ghostty terminal palette. Explicit
RGB diff backgrounds also work in other true-color terminals. Layout remains
controlled by existing delta settings.

References: [Ghostty themes](https://ghostty.org/docs/features/theme),
[delta custom themes](https://github.com/dandavison/delta/blob/main/manual/src/custom-themes.md).
