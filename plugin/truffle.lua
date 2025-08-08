-- Autoload for truffle.nvim
-- Provides default setup and commands on startup
if vim.g.loaded_truffle_autoload then
  return
end
vim.g.loaded_truffle_autoload = true

local ok, mod = pcall(require, "truffle")
if not ok then
  return
end

-- Default setup; users can override by calling require('truffle').setup({...}) in their config
mod.setup({})
