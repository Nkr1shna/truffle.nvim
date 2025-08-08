### truffle.nvim ✨

A tiny, cheerful side-panel for Neovim that docks a terminal on the right by default and runs the AI/CLI of your choice. Bring your own agent, we bring the vibes.

- **You choose the brain**: set a mandatory `command` (e.g., `cursor-agent`, `crush`, `claude`, `npx gemini`)
- **Right-side dock (default)**: neat vertical split on the right; configurable `side = 'right' | 'bottom' | 'left'`
- **Keymaps**: defaults under `<leader>t...` (toggle, send selection/file/input)

### Demo 🎥

![truffle_in_action](https://github.com/user-attachments/assets/e958e5dd-9269-4d28-9f47-6a96a4f442e8)

### Requirements 🧰

- Neovim 0.7+ (0.9+ recommended)
- A CLI on your `PATH` to run in the panel (the plugin doesn’t install CLIs for you) — see [Get an agent CLI](#get-an-agent-cli)

### Installation 🚀

#### lazy.nvim (command is required)

```lua
{
  "Nkr1shna/truffle.nvim",
  config = function()
    require("truffle").setup({
      command = "cursor-agent",         -- REQUIRED: set your CLI command, make sure it is available in path
    })
  end,
}
```

#### packer.nvim (command is required)

```lua
use({
  "Nkr1shna/truffle.nvim",
  config = function()
    require("truffle").setup({ command = "cursor-agent" })
  end,
})
```

#### dein.vim (command is required)

```vim
call dein#add('Nkr1shna/truffle.nvim')
" Then in your init.lua or after/plugin file
lua << EOF
require('truffle').setup({ command = 'cursor-agent' })
EOF
```

#### vim-plug (command is required)

```vim
Plug 'Nkr1shna/truffle.nvim'
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

The panel reuses the same terminal buffer across toggles. When opened, it docks to the configured `side` (default: right). If `side = 'bottom'`, `size` controls height and the panel uses the full editor width; otherwise `size` controls width.

### Configuration ⚙️

Call `require('truffle').setup({...})` with options (command is required). The default dock is right.

```lua
require('truffle').setup({
  command = "cursor-agent",      -- REQUIRED: choose any CLI command

  -- Layout & size
  side = 'right',                 -- 'right' | 'bottom' | 'left' (default: 'right')
  size = nil,                     -- number (cols/rows) or percentage string like '33%'

  -- Window/buffer look
  buffer_name = '[Truffle]',      -- friendly buffer name (visible in statusline/tabline)
  buflisted = false,              -- whether buffer is listed in :ls (false => only in :ls!)

  -- Behavior & keymaps
  start_insert = true,            -- start in terminal insert mode
  create_mappings = true,         -- install default keymaps
  mappings = {
    toggle = "<leader>tc",
    send_selection = "<leader>ts",
    send_file = "<leader>tf",
    send_input = "<leader>ti",
  },
  -- toggle_mapping = "<leader>tc", -- deprecated; still works for toggle only
})
```

Prefer your own keymaps? Disable the default and add your favorite:

```lua
require('truffle').setup({
  command = "cursor-agent",
  create_mappings = false,
})

-- Toggle
vim.keymap.set('n', '<leader>tc', function() require('truffle').toggle() end, { desc = 'Truffle: Toggle panel' })
-- Send selection (visual mode)
vim.keymap.set('v', '<leader>ts', function() require('truffle').send_visual() end, { desc = 'Truffle: Send selection' })
-- Send current file
vim.keymap.set('n', '<leader>tf', function() require('truffle').send_file({ path = 'current' }) end, { desc = 'Truffle: Send file' })
-- Prompt for input text and send
vim.keymap.set('n', '<leader>ti', function()
  vim.ui.input({ prompt = 'Truffle text: ' }, function(input)
    if input and input ~= '' then require('truffle').send_text(input) end
  end)
end, { desc = 'Truffle: Send input text' })
```

### Configuration reference 📘

The table below lists each option with its type, whether it is required, and its default value.

| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `command` | string | Yes | — | CLI to run inside the panel. Must be in your `PATH`. |
| `side` | "right" \| "bottom" \| "left" | No | `"right"` | Where to dock the panel. |
| `size` | number or percentage string `"NN%"` | No | `nil` | Absolute size for the split. If percentage, computed from `vim.o.columns` (side) or `vim.o.lines` (bottom). When `side = 'bottom'`, this is the height (bottom dock is always full width); otherwise, width. |
| `buffer_name` | string | No | `"[Truffle]"` | Friendly name visible in statusline/tabline. |
| `buflisted` | boolean | No | `false` | If `true`, buffer shows in `:ls`; otherwise only in `:ls!`. |
| `start_insert` | boolean | No | `true` | Enter terminal insert mode on open. |
| `create_mappings` | boolean | No | `true` | Install default keymaps. |
| `mappings` | table of strings | No | see below | Override any default mapping: `toggle`, `send_selection`, `send_file`, `send_input`. |
| `toggle_mapping` | string (deprecated) | No | `nil` | Back-compat single mapping for toggle only. Prefer `mappings.toggle`. |

Default mappings:
- `toggle`: `"<leader>tc"`
- `send_selection`: `"<leader>ts"`
- `send_file`: `"<leader>tf"`
- `send_input`: `"<leader>ti"`

Sizing behavior when `size` is not set:
- **Bottom dock**: full editor width; uses a default height of `12` rows.
- **Left/Right dock**: uses a default width of `65` columns.

### Commands 🧪

- `:TruffleToggle` – Toggle the terminal panel
- `:TruffleOpen` – Open/create and focus the terminal panel
- `:TruffleClose` – Close the terminal panel window
- `:TruffleFocus` – Focus the terminal panel (opens if missing)
  
### Default keymaps ⌨️

- Normal: `<leader>tc` – Toggle panel
- Visual: `<leader>ts` – Send selection
- Normal: `<leader>tf` – Send current file
- Normal: `<leader>ti` – Prompt for text and send
  

### Notes 📝

- If the configured `command` is not found on `PATH`, the plugin will show an error.
- The same buffer is reused across toggles to retain session context.

#### Get an agent CLI
- Cursor Agent: https://docs.cursor.com/en/cli/installation
- Crush: https://github.com/charmbracelet/crush
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Claude Code/CLI: https://docs.anthropic.com/en/docs/claude-code/setup

### License

MIT
