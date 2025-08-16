# 🍄 truffle.nvim

> *Because the sweetest workflows come from tasting many truffles, not just sticking to one - experiment and discover what works for you!*

A Neovim plugin that adds a cozy sidebar terminal where you can chat with your favorite CLI-based AI tools like `cursor-agent`, `gemini`, `codex`, `opencode`, and friends. Think of it as your personal AI assistant panel that's always just a keystroke away! 

## ✨ Features

- 🎯 **Multi-Profile Support**: Switch between different AI tools seamlessly
- 📍 **Flexible Layout**: Sidebar on left, right, or bottom - you choose!
- 🚀 **Quick Actions**: Send files or selections with ease

## Demo 🎥

![truffle_in_action](https://github.com/user-attachments/assets/e958e5dd-9269-4d28-9f47-6a96a4f442e8)

![swtch](https://github.com/user-attachments/assets/091a0c80-ba0b-47f6-b3a3-0d91ecef8572)

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Nkr1shna/truffle.nvim",
  config = function()
    require("truffle").setup({
      profiles = {
        cursor = {
          command = "cursor-agent",
          default = true,
        },
        codex = {
          command = "codex",
          env = "~/.env"
        },
        gemini = {
          command = "gemini-cli",
          cwd = "~/projects/current",
          env = {
            GOOGLE_API_KEY="YOUR_API_KEY"
          }
        },
      }
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "Nkr1shna/truffle.nvim",
  config = function()
    require("truffle").setup({
      profiles = {
        cursor = { command = "cursor-agent", default = true },
        claude = { command = "claude-cli" },
      }
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Nkr1shna/truffle.nvim'

" Add to your init.lua or in a lua block:
lua << EOF
require("truffle").setup({
  profiles = {
    cursor = { command = "cursor-agent", default = true },
    claude = { command = "claude-cli" },
  }
})
EOF
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('Nkr1shna/truffle.nvim')

" Configuration in init.lua or lua block
lua require("truffle").setup({ profiles = { cursor = { command = "cursor-agent", default = true } } })
```

## ⚙️ Configuration

### Complete Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `string` | `"right"` | Panel position: `"right"`, `"left"`, or `"bottom"` |
| `size` | `number/string` | `nil` | Panel size (cols/rows) or percentage like `"33%"` |
| `start_insert` | `boolean` | `false` | Start in insert mode when opening |
| `create_mappings` | `boolean` | `true` | Create default key mappings |
| `mappings` | `table` | See below | Custom key mapping overrides |
| `profiles` | `table` | **Required** | Profile configurations (see below) |


### Default Key Mappings

| Mapping | Default Key | Mode | Description |
|---------|-------------|------|-------------|
| `toggle` | `<leader>tc` | Normal | Toggle the truffle panel |
| `send_selection` | `<leader>ts` | Visual | Send selected text |
| `send_file` | `<leader>tf` | Normal | Send current file |
| `next_profile` | `]c` | Normal | Switch to next profile |
| `prev_profile` | `[c` | Normal | Switch to previous profile |

### Profile Configuration

Each profile is a table with the following options:

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `command` | `string` | ✅ | CLI command to execute |
| `cwd` | `string` | ❌ | Working directory for the command |
| `env` | `table/string` | ❌ | Environment variables (table) or path to .env file |
| `default` | `boolean` | ❌ | Mark as default profile when multiple profiles are configured (only one allowed) |

## 🚀 Usage Examples

### Basic Setup

```lua
require("truffle").setup({
  side = "right",
  size = "30%",
  profiles = {
    cursor = {
      command = "cursor-agent",
      default = true,
    },
    claude = {
      command = "claude-cli --interactive",
      cwd = "~/code/current-project",
    },
    gemini = {
      command = "gemini-chat",
      env = { API_KEY = "your-key-here" },
    },
  }
})
```

### Advanced Setup with Environment Files

```lua
require("truffle").setup({
  side = "bottom",
  size = 15,
  start_insert = true,  -- Override default to start in insert mode
  mappings = {
    toggle = "<leader>ai",
    send_selection = "<leader>as",
    send_file = "<leader>af",
  },
  profiles = {
    work_claude = {
      command = "claude",
      cwd = "~/work/projects",
      env = "~/.config/truffle/work.env",  -- Load from file
      default = true,
    },
    personal_gpt = {
      command = "codex",
      cwd = "~/personal",
      env = {
        OPENAI_API_KEY = "sk-...",
        MODEL = "gpt-4",
      },
    },
  }
})
```

### Minimal Setup

```lua
require("truffle").setup({
  profiles = {
    ai = { command = "cursor-agent", default = true }
  }
})
```

## 🎮 Commands

| Command | Description |
|---------|-------------|
| `:TruffleToggle` | Toggle the truffle panel |
| `:TruffleOpen` | Open the truffle panel |
| `:TruffleClose` | Close the truffle panel |
| `:TruffleFocus` | Focus the truffle panel |
| `:TruffleSwitchProfile [name] [cwd=path]` | Switch to a different profile by providing another cwd|


### Profile Switching Examples

```vim
" List all available profiles
:TruffleSwitchProfile

" Switch to claude profile
:TruffleSwitchProfile claude

" Switch to cursor profile with custom working directory
:TruffleSwitchProfile cursor cwd=~/special-project
```

## 🛠️ API Functions

```lua
local truffle = require("truffle")

-- Panel control
truffle.toggle()
truffle.open()
truffle.close()
truffle.focus()

-- Send content
truffle.send_visual()  -- Send current visual selection
truffle.send_file({ path = "current" })

-- Profile management
truffle.switch_profile("claude", { cwd = "/path/to/project" })
truffle.next_profile()
truffle.prev_profile()

-- State inspection
local current = truffle.get_current_profile()
local jobs = truffle.get_background_jobs()
```

## 🎭 Tips & Tricks

1. **Quick Profile Switching**: Use `]c` and `[c` to cycle through your AI tools without leaving your keyboard home row!

2. **Environment Files**: Store your API keys in separate `.env` files for each profile:
   ```bash
   # ~/.config/truffle/claude.env
   ANTHROPIC_API_KEY=your_key_here
   MODEL=claude-3-sonnet
   ```

3. **Project-Specific AI**: Set different working directories per profile to keep context relevant:
   ```lua
   profiles = {
     work = { command = "claude-cli", cwd = "~/work" },
     personal = { command = "gpt-cli", cwd = "~/personal" },
   }
   ```

4. **Send Files Easily**: Use `<leader>tf` to send the current file to your AI for review or questions.

5. **Custom Mappings**: Don't like the defaults? Change them:
   ```lua
   mappings = {
     toggle = "<C-a>",  -- Ctrl+a to toggle
     send_selection = "gs",  -- gs in visual mode
   }
   ```

## 🤝 Contributing

Found a bug? Have a feature idea? Want to add support for a new AI tool? Contributions are welcome! 

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

*Happy coding with your AI companions! 🍄✨*
