### truffle.nvim

A lightweight Neovim plugin that opens a right-side terminal running `truffle` (configurable), giving you a chat-like side panel inside Neovim.

- **Default toggle**: `<leader>tc`
- **Layout**: vertical split docked to the right
- **Command**: runs `truffle` in a terminal buffer (configurable)

### Requirements

- Neovim 0.7+ (0.9+ recommended)
- The CLI you want to run must be available on your `PATH` (this plugin does not install CLIs for you).

### Installation

#### lazy.nvim

```lua
{
  "your-username/truffle.nvim",
  config = function()
    require("truffle").setup({
      -- optional overrides
      -- command = "truffle --flag",   -- default: "truffle"
      -- width = 65,                    -- right split width
      -- start_insert = true,           -- enter insert/terminal mode on open
      -- create_mappings = true,        -- set default keymaps
      -- toggle_mapping = "<leader>tc", -- default toggle keybinding
      -- no auto-install; please install your CLI yourself
    })
  end,
}
```

#### packer.nvim

```lua
use({
  "your-username/truffle.nvim",
  config = function()
    require("truffle").setup({})
  end,
})
```

#### dein.vim

```vim
call dein#add('your-username/truffle.nvim')
" Then in your init.lua or after/plugin file
lua << EOF
require('truffle').setup({})
EOF
```

#### vim-plug

```vim
Plug 'your-username/truffle.nvim'
" Then in your init.lua or after/plugin file
lua << EOF
require('truffle').setup({})
EOF
```

### Usage

- **Toggle panel**: press `<leader>tc` (default) or run:
  - `:TruffleToggle`
- **Open**: `:TruffleOpen`
- **Close**: `:TruffleClose`
- **Focus**: `:TruffleFocus`

The panel reuses the same terminal buffer across toggles. When opened, the window is moved to the right (`:wincmd L`) and resized to the configured width.

### Configuration

Call `require('truffle').setup({...})` with options:

```lua
require('truffle').setup({
  command = "truffle",         -- choose any CLI command
  width = 65,                   -- right split width in columns
  start_insert = true,          -- start in terminal insert mode
  create_mappings = true,       -- install default keymaps
  toggle_mapping = "<leader>tc", -- default toggle
})
```

You can disable the default mapping and add your own:

```lua
require('truffle').setup({
  create_mappings = false,
})

vim.keymap.set('n', '<leader>tc', function()
  require('truffle').toggle()
end, { desc = 'Truffle: Toggle panel' })
```

### Commands

- `:TruffleToggle` – Toggle the right-side terminal
- `:TruffleOpen` – Open/create and focus the right-side terminal
- `:TruffleClose` – Close the right-side terminal window
- `:TruffleFocus` – Focus the terminal window (opens if missing)
  

### Notes

- If the configured `command` is not found on `PATH`, the plugin shows a helpful error (with a docs link for known CLIs) and does not attempt to install anything.
- The same buffer is reused across toggles to retain session context.

### Using different CLIs

You can point the plugin to any CLI:

```lua
require('truffle').setup({
  -- Default
  command = "truffle",
  -- Cursor Agent
  -- command = "cursor-agent",
  -- Crush
  -- command = "crush",
  -- Gemini (via npx)
  -- command = "npx -y @google/generative-ai-cli@latest chat",
  -- Claude (example, adjust per docs)
  -- command = "claude",
})
```

Helpful docs:
- Cursor Agent: https://docs.cursor.com/en/cli/installation
- Crush: https://github.com/charmbracelet/crush
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Claude Code/CLI: https://docs.anthropic.com/en/docs/claude-code/setup

### License

MIT
