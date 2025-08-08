local M = {}

local state = require("truffle.state")
local Config = require("truffle.config")
local Terminal = require("truffle.terminal")
local Commands = require("truffle.commands")
local Keymaps = require("truffle.keymaps")

function M.open()
	Terminal.open(state)
end

function M.close()
	Terminal.close(state)
end

function M.toggle()
	Terminal.toggle(state)
end

function M.focus()
	Terminal.focus(state)
end

function M.send_text(text)
	Terminal.send_text(state, text)
end

function M.send_visual()
	Terminal.send_visual(state)
end

function M.send_file(opts)
	Terminal.send_file(state, opts)
end

function M.setup(opts)
	opts = opts or {}

	if not opts.command or opts.command == "" then
		state.config = vim.deepcopy(Config.DEFAULT_CONFIG)
		vim.notify(
			"truffle.nvim: setup requires a 'command' option. Example: require('truffle').setup({ command = 'cursor-agent' })",
			vim.log.levels.ERROR
		)
		return
	end

	if not Config.validate_opts(opts) then
		return
	end

	state.config = Config.merge_config(opts)

	Commands.create_user_commands(state, M)
	Keymaps.create_default_keymaps(state, M, Config.DEFAULT_CONFIG.mappings)
end

return M
