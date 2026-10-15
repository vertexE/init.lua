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

## Obsidian

Local dark theme: [`obsidian/Forest Canopy`](obsidian/Forest%20Canopy/).
Includes editor, reading view, sidebar, headings, links, code, and graph colors.
Uses built-in CSS variables; no plugins required. Light mode keeps Obsidian defaults.

1. Find vault folder. Use its config folder (`.obsidian` by default; substitute
   custom config folder if configured).
2. Copy entire `Forest Canopy` folder into `<vault>/.obsidian/themes/`.
   Folder name must match manifest name exactly. Result:

   ```text
   <vault>/.obsidian/themes/Forest Canopy/
       manifest.json
       theme.css
   ```

   macOS terminal alternative (replace vault path):

   ```sh
   mkdir -p "/path/to/vault/.obsidian/themes/Forest Canopy"
   cp "$HOME/.config/nvim/external/obsidian/Forest Canopy/manifest.json" "/path/to/vault/.obsidian/themes/Forest Canopy/"
   cp "$HOME/.config/nvim/external/obsidian/Forest Canopy/theme.css" "/path/to/vault/.obsidian/themes/Forest Canopy/"
   ```

3. Restart Obsidian. Open **Settings → Appearance**, select **Forest Canopy**
   under **Themes**, set **Base color scheme → Dark**.
4. To update, copy files again. Restart after manifest changes. Installation
   applies per vault; repeat for other vaults.

If theme doesn't appear, check folder nesting and both filenames. Finder hides
`.obsidian` by default; press `Cmd+Shift+.` to show hidden files.

Reference: [Obsidian theme development and local loading](https://docs.obsidian.md/Themes/App+themes/Build+a+theme).
