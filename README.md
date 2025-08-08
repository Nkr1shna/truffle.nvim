### truffle.nvim ✨

A tiny, cheerful side-panel for Neovim that docks a terminal on the right and runs the AI/CLI of your choice. Bring your own agent, we bring the vibes.

- **You choose the brain**: set a mandatory `command` (e.g., `cursor-agent`, `crush`, `claude`, `npx gemini`)
- **Right-side dock**: neat vertical split on the right
- **Keymaps**: defaults under `<leader>t...` (toggle, send selection/file/input)
- **Layout**: vertical split docked to the right
- **Command**: runs `truffle` in a terminal buffer (configurable)

### Requirements 🧰

- Neovim 0.7+ (0.9+ recommended)
- A CLI on your `PATH` to run in the panel (the plugin doesn’t install CLIs for you) — see [Get an agent CLI](#get-an-agent-cli)

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
      -- create_mappings = true,         -- install default keymaps
      -- mappings = {                    -- override any of the defaults below
      --   toggle = "<leader>tc",
      --   send_selection = "<leader>ts",
      --   send_file = "<leader>tf",
      --   send_input = "<leader>ti",
      -- },
      -- toggle_mapping = "<leader>tc",  -- deprecated: still supported for toggle (back-compat)
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

### Commands 🧪

- `:TruffleToggle` – Toggle the right-side terminal
- `:TruffleOpen` – Open/create and focus the right-side terminal
- `:TruffleClose` – Close the right-side terminal window
- `:TruffleFocus` – Focus the terminal window (opens if missing)
  
### Default keymaps ⌨️

- Normal: `<leader>tc` – Toggle panel
- Visual: `<leader>ts` – Send selection
- Normal: `<leader>tf` – Send current file
- Normal: `<leader>ti` – Prompt for text and send
  

### Notes 📝

- If the configured `command` is not found on `PATH`, the plugin throw an error.
- The same buffer is reused across toggles to retain session context.

#### Get an agent CLI
- Cursor Agent: https://docs.cursor.com/en/cli/installation
- Crush: https://github.com/charmbracelet/crush
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Claude Code/CLI: https://docs.anthropic.com/en/docs/claude-code/setup

### License

MIT
