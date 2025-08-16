local M = {}

local state = require("truffle.state")
local Config = require("truffle.config")
local Terminal = require("truffle.terminal")
local Commands = require("truffle.commands")
local Keymaps = require("truffle.keymaps")
local Utils = require("truffle.utils")

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

function M.send_visual()
	Terminal.send_visual(state)
end

function M.send_file(opts)
	Terminal.send_file(state, opts)
end

function M.get_current_profile()
	return state.current_profile
end

function M.get_state()
	return state
end

function M.get_background_jobs()
	local jobs = {}
	for profile_name, job_id in pairs(state.profile_jobs or {}) do
		jobs[profile_name] = {
			job_id = job_id,
			running = Utils.is_job_running(job_id),
		}
	end
	return jobs
end

function M.next_profile()
	if not state.base_config or not state.base_config.profiles then
		vim.notify("truffle.nvim: no profiles configured", vim.log.levels.WARN)
		return false
	end

	-- Get sorted list of profile names for consistent ordering
	local profile_names = {}
	for name, _ in pairs(state.base_config.profiles) do
		table.insert(profile_names, name)
	end
	table.sort(profile_names)

	if #profile_names == 0 then
		vim.notify("truffle.nvim: no profiles available", vim.log.levels.WARN)
		return false
	end

	if #profile_names == 1 then
		vim.notify("truffle.nvim: only one profile available: " .. profile_names[1], vim.log.levels.INFO)
		return false
	end

	-- Find current profile index
	local current_index = nil
	for i, name in ipairs(profile_names) do
		if name == state.current_profile then
			current_index = i
			break
		end
	end

	-- Move to next profile (wrap around to first if at end)
	local next_index = current_index and (current_index % #profile_names) + 1 or 1
	local next_profile_name = profile_names[next_index]

	return M.switch_profile(next_profile_name)
end

function M.prev_profile()
	if not state.base_config or not state.base_config.profiles then
		vim.notify("truffle.nvim: no profiles configured", vim.log.levels.WARN)
		return false
	end

	-- Get sorted list of profile names for consistent ordering
	local profile_names = {}
	for name, _ in pairs(state.base_config.profiles) do
		table.insert(profile_names, name)
	end
	table.sort(profile_names)

	if #profile_names == 0 then
		vim.notify("truffle.nvim: no profiles available", vim.log.levels.WARN)
		return false
	end

	if #profile_names == 1 then
		vim.notify("truffle.nvim: only one profile available: " .. profile_names[1], vim.log.levels.INFO)
		return false
	end

	-- Find current profile index
	local current_index = nil
	for i, name in ipairs(profile_names) do
		if name == state.current_profile then
			current_index = i
			break
		end
	end

	-- Move to previous profile (wrap around to last if at beginning)
	local prev_index = current_index and ((current_index - 2) % #profile_names) + 1 or #profile_names
	local prev_profile_name = profile_names[prev_index]

	return M.switch_profile(prev_profile_name)
end

function M.switch_profile(profile_name, opts)
	opts = opts or {}

	if not state.base_config then
		vim.notify("truffle.nvim: no profiles configured", vim.log.levels.ERROR)
		return false
	end

	if not state.base_config.profiles then
		vim.notify("truffle.nvim: no profiles configured", vim.log.levels.ERROR)
		return false
	end

	if not state.base_config.profiles[profile_name] then
		vim.notify("truffle.nvim: profile '" .. profile_name .. "' not found", vim.log.levels.ERROR)
		return false
	end

	-- Get new config for the profile
	local new_config = Config.get_profile_config(state.base_config, profile_name)

	-- Apply runtime overrides
	local runtime_changes = {}

	-- Handle runtime CWD override
	if opts.cwd then
		new_config.cwd = opts.cwd
		table.insert(runtime_changes, "cwd=" .. opts.cwd)
	elseif not new_config.cwd then
		-- Use current directory if no CWD is set
		new_config.cwd = vim.fn.getcwd()
		table.insert(runtime_changes, "cwd=" .. new_config.cwd)
	end

	-- Perform seamless switch if terminal is currently open, otherwise open it
	local switched_seamlessly = false
	local auto_opened = false
	if Utils.is_valid_win(state.winid) then
		Terminal.switch_to_profile(state, profile_name, new_config)
		switched_seamlessly = true
	else
		-- Update config and auto-open terminal for new profile
		state.current_profile = profile_name
		state.config = new_config
		Terminal.open(state)
		auto_opened = true
	end

	-- Build notification message
	local message = "truffle.nvim: switched to profile '" .. profile_name .. "'"
	if #runtime_changes > 0 then
		message = message .. " (" .. table.concat(runtime_changes, ", ") .. ")"
	end
	if switched_seamlessly then
		message = message .. " [seamlessly switched]"
	elseif auto_opened then
		message = message .. " [opened terminal]"
	end

	-- vim.notify(message, vim.log.levels.INFO)  -- Profile switch notifications silenced
	return true
end

function M.setup(opts)
	opts = opts or {}

	-- Handle both old-style (command only) and new-style (profiles) setup
	local needs_command = not opts.profiles
	if needs_command and (not opts.command or opts.command == "") then
		state.config = vim.deepcopy(Config.DEFAULT_CONFIG)
		vim.notify(
			"truffle.nvim: setup requires either a 'command' option or 'profiles' configuration. Example: require('truffle').setup({ command = 'cursor-agent' }) or profiles = { cursor = { command = 'cursor-agent' }, claude = { command = 'claude-cli' } }",
			vim.log.levels.ERROR
		)
		return
	end

	if not Config.validate_opts(opts) then
		return
	end

	-- Store the base config
	state.base_config = Config.merge_config(opts)

	-- If profiles are configured, set up the default profile
	if state.base_config.profiles then
		local active_profile = Config.get_active_profile_name(state.base_config)
		if active_profile then
			state.current_profile = active_profile
			state.config = Config.get_profile_config(state.base_config, active_profile)
		else
			vim.notify("truffle.nvim: no default profile found and no profiles available", vim.log.levels.ERROR)
			return
		end
	else
		-- Traditional single-command setup
		state.config = state.base_config
		state.current_profile = nil
	end

	Commands.create_user_commands(state, M)
	Keymaps.create_default_keymaps(state, M, Config.DEFAULT_CONFIG.mappings)

	-- Setup cleanup on Neovim exit
	local cleanup_group = vim.api.nvim_create_augroup("TruffleCleanup", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = cleanup_group,
		callback = function()
			Terminal.cleanup_all_jobs(state)
		end,
		desc = "Cleanup all Truffle background processes on exit",
	})
end

return M
