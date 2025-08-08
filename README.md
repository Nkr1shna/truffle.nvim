### truffle.nvim ✨

A tiny, cheerful side-panel for Neovim that docks a terminal on the right and runs the AI/CLI of your choice. Bring your own agent, we bring the vibes.

- **You choose the brain**: set a mandatory `command` (e.g., `cursor-agent`, `crush`, `claude`, `npx gemini`)
- **Right-side dock**: neat vertical split on the right
- **One key to rule them all**: default toggle is `<leader>tc`
- **Layout**: vertical split docked to the right
- **Command**: runs `truffle` in a terminal buffer (configurable)

### Requirements 🧰

- Neovim 0.7+ (0.9+ recommended)
- A CLI on your `PATH` to run in the panel (the plugin doesn’t install CLIs for you)

### Installation 🚀

#### lazy.nvim (command is required)

```lua
{
  "your-username/truffle.nvim",
  config = function()
    require("truffle").setup({
      command = "cursor-agent",         -- REQUIRED: set your CLI command, make sure it is available in path
      -- optional overrides
      -- width = 65,                     -- right split width
      -- start_insert = true,            -- enter insert/terminal mode on open
      -- create_mappings = true,         -- set default keymaps
      -- toggle_mapping = "<leader>tc",  -- default toggle keybinding
    })
  end,
}
```

#### packer.nvim (command is required)

```lua
use({
  "your-username/truffle.nvim",
  config = function()
    require("truffle").setup({ command = "cursor-agent" })
  end,
})
```

#### dein.vim (command is required)

```vim
call dein#add('your-username/truffle.nvim')
" Then in your init.lua or after/plugin file
lua << EOF
require('truffle').setup({ command = 'cursor-agent' })
EOF
```

#### vim-plug (command is required)

```vim
Plug 'your-username/truffle.nvim'
" Then in your init.lua or after/plugin file
lua << EOF
require('truffle').setup({ command = 'cursor-agent' })
EOF
```

### Usage 🎛️

- **Toggle panel**: press `<leader>tc` (default) or run:
  - `:TruffleToggle`
- **Open**: `:TruffleOpen`
- **Close**: `:TruffleClose`
- **Focus**: `:TruffleFocus`

The panel reuses the same terminal buffer across toggles. When opened, the window is moved to the right (`:wincmd L`) and resized to the configured width.

### Configuration ⚙️

Call `require('truffle').setup({...})` with options (command is required):

```lua
require('truffle').setup({
  command = "cursor-agent",      -- REQUIRED: choose any CLI command
  width = 65,                     -- right split width in columns
  start_insert = true,            -- start in terminal insert mode
  create_mappings = true,         -- install default keymaps
  toggle_mapping = "<leader>tc", -- default toggle
})
```

Prefer your own keymaps? Disable the default and add your favorite:

```lua
require('truffle').setup({
  command = "cursor-agent",
  create_mappings = false,
})

vim.keymap.set('n', '<leader>tc', function()
  require('truffle').toggle()
end, { desc = 'Truffle: Toggle panel' })
```

### Commands 🧪

- `:TruffleToggle` – Toggle the right-side terminal
- `:TruffleOpen` – Open/create and focus the right-side terminal
- `:TruffleClose` – Close the right-side terminal window
- `:TruffleFocus` – Focus the terminal window (opens if missing)
  

### Notes 📝

- If the configured `command` is not found on `PATH`, the plugin shows a helpful error (with a docs link for known CLIs) and does not attempt to install anything.
- The same buffer is reused across toggles to retain session context.

### Using different CLIs 🧠

You can point the plugin to any CLI (set `command` accordingly):

```lua
require('truffle').setup({
  -- Cursor Agent (example)
  command = "cursor-agent",
  -- Crush
  -- command = "crush",
  -- Gemini (via npx)
  -- command = "npx -y @google/generative-ai-cli@latest chat",
  -- Claude (example, adjust per docs)
  -- command = "claude",
})
```

### Pro tips 💡
- Want the panel hidden from buffer tabs? It already is (`buflisted=false`).
- Want statusline/tabline to ignore it too? Filter by `buftype='terminal'` or `filetype='truffle'` in your statusline config.
- Resize on the fly with `:vert resize +5` or set `width` in setup.

Helpful docs:
- Cursor Agent: https://docs.cursor.com/en/cli/installation
- Crush: https://github.com/charmbracelet/crush
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Claude Code/CLI: https://docs.anthropic.com/en/docs/claude-code/setup

### License

MIT
