local Utils = require("truffle.utils")
local Selection = require("truffle.selection")

local Terminal = {}

local termclose_group = vim.api.nvim_create_augroup("TruffleTermClose", { clear = false })

local function setup_termclose_autocmd(state, buf, profile_name)
	pcall(vim.api.nvim_clear_autocmds, { group = termclose_group, buffer = buf })
	vim.api.nvim_create_autocmd("TermClose", {
		group = termclose_group,
		buffer = buf,
		callback = function()
			-- Clean up both legacy and profile-specific job tracking
			if profile_name and state.profile_jobs then
				state.profile_jobs[profile_name] = nil
			end
			if state.current_profile == profile_name then
				state.jobid = nil
			end
			pcall(
				vim.notify,
				"truffle.nvim: terminal process exited for profile: " .. (profile_name or "unknown"),
				vim.log.levels.INFO
			)
		end,
	})
end

local function start_job_in_current_buf(state)
	local job_opts = { term = true }
	if state.config and state.config.cwd then
		job_opts.cwd = state.config.cwd
	end
	if state.config and state.config.env then
		job_opts.env = state.config.env
	end
	local ok, job = pcall(vim.fn.jobstart, { state.config.command }, job_opts)
	if not ok or not job or job <= 0 then
		vim.notify("Failed to start '" .. state.config.command .. "'. Is it in your PATH?", vim.log.levels.ERROR)
		return nil
	end

	-- Update both legacy and profile-specific job tracking
	state.jobid = job
	if state.current_profile then
		state.profile_jobs[state.current_profile] = job
		state.profile_buffers[state.current_profile] = vim.api.nvim_get_current_buf()
	end

	setup_termclose_autocmd(state, vim.api.nvim_get_current_buf(), state.current_profile)
	if state.config.start_insert then
		vim.cmd("startinsert")
	end
	return job
end

local function open_new_terminal(state, win)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	pcall(vim.api.nvim_set_current_win, win)

	vim.bo[buf].buflisted = false
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "truffle"

	-- Generate dynamic buffer name based on current profile
	local buffer_name = "[Truffle]"
	print(state.current_profile .. " is the current profile")
	if state.current_profile then
		buffer_name = "[Truffle - " .. state.current_profile .. "]"
	end
	pcall(vim.api.nvim_buf_set_name, buf, buffer_name)

	state.bufnr = buf
	state.winid = win

	local job = start_job_in_current_buf(state)
	if not job then
		return nil, nil
	end
	return buf, win
end

local function reopen_existing_buffer(state, win)
	vim.api.nvim_win_set_buf(win, state.bufnr)
	pcall(vim.api.nvim_set_current_win, win)
	if Utils.is_valid_buf(state.bufnr) then
		vim.bo[state.bufnr].buflisted = false
	end

	if not Utils.is_job_running(state.jobid) then
		start_job_in_current_buf(state)
	else
		if state.config.start_insert then
			vim.cmd("startinsert")
		end
	end

	state.winid = win
	return state.bufnr, win
end

local function ensure_panel_visible_and_focus_insert(state)
	if not Utils.is_valid_win(state.winid) then
		Terminal.open(state)
	end
	if Utils.is_valid_win(state.winid) then
		pcall(vim.api.nvim_set_current_win, state.winid)
		vim.cmd("startinsert")
	end
end

local function ensure_job_ready(state)
	if not Utils.is_job_running(state.jobid) then
		vim.notify("truffle.nvim: terminal job is not running. Open the panel first.", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function send_to_terminal(state, data)
	ensure_panel_visible_and_focus_insert(state)
	if not ensure_job_ready(state) then
		return
	end
	pcall(vim.fn.chansend, state.jobid, data)
end

function Terminal.open(state)
	-- If window is visible, ensure job alive; if not, relaunch in-place
	if Utils.is_valid_win(state.winid) then
		pcall(vim.api.nvim_set_current_win, state.winid)
		if Utils.is_valid_buf(state.bufnr) and not Utils.is_job_running(state.jobid) then
			start_job_in_current_buf(state)
		end
		return
	end

	if not state.config or not state.config.command or state.config.command == "" then
		vim.notify(
			"truffle.nvim: 'command' option is required. Set it via require('truffle').setup({ command = '<your-cli>' }).",
			vim.log.levels.ERROR
		)
		return
	end

	if not Utils.ensure_command_available(state.config.command) then
		local url = Utils.guess_docs_url_for_command(state.config.command)
		local msg = "Command not found: '" .. state.config.command .. "'. Install it or change the configured command."
		if url then
			msg = msg .. " See: " .. url
		end
		vim.notify("truffle.nvim: " .. msg, vim.log.levels.ERROR)
		return
	end

	local side = (state.config and state.config.side) or "right"
	local win = Utils.create_split_on_side(side)

	-- Compute desired size (absolute or percentage)
	local size_value = nil
	local cfg_size = state.config and state.config.size or nil
	if type(cfg_size) == "string" then
		local pct = tonumber(cfg_size:match("^(%d+)%%$"))
		if pct and pct > 0 then
			if side == "bottom" then
				size_value = math.floor((vim.o.lines or 24) * (pct / 100))
			else
				size_value = math.floor((vim.o.columns or 80) * (pct / 100))
			end
		end
	elseif type(cfg_size) == "number" and cfg_size > 0 then
		size_value = cfg_size
	end

	if not size_value then
		if side == "bottom" then
			-- Sensible default height when docked at bottom
			size_value = 12
		else
			-- Default width for left/right docks when size is not provided
			size_value = 65
		end
	end

	if side == "bottom" then
		Utils.set_window_height(win, size_value)
	else
		Utils.set_window_width(win, size_value)
	end
	Utils.apply_window_look(win, side)

	if Utils.is_valid_buf(state.bufnr) then
		reopen_existing_buffer(state, win)
	else
		open_new_terminal(state, win)
	end
end

function Terminal.close(state)
	if Utils.is_valid_win(state.winid) then
		pcall(vim.api.nvim_win_close, state.winid, true)
	end
	state.winid = nil
end

function Terminal.toggle(state)
	if Utils.is_valid_win(state.winid) then
		Terminal.close(state)
	else
		Terminal.open(state)
	end
end

function Terminal.focus(state)
	if Utils.is_valid_win(state.winid) then
		pcall(vim.api.nvim_set_current_win, state.winid)
	else
		Terminal.open(state)
	end
end

function Terminal.send_visual(state)
	local text = Selection.get_visual_selection_text()
	text = text .. "\n"
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
	if not text or text == "" then
		vim.notify("truffle.nvim: visual selection is empty.", vim.log.levels.WARN)
		return
	end
	send_to_terminal(state, text)
end

function Terminal.send_file(state, opts)
	opts = opts or {}
	local lines = nil
	if type(opts.path) == "string" and opts.path ~= "" and opts.path ~= "current" then
		if vim.fn.filereadable(opts.path) ~= 1 then
			vim.notify("truffle.nvim: file not readable: " .. opts.path, vim.log.levels.ERROR)
			return
		end
		lines = vim.fn.readfile(opts.path)
	else
		local bufnr = vim.api.nvim_get_current_buf()
		lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	end
	table.insert(lines, "")
	send_to_terminal(state, lines)
end

-- Hide current terminal window without killing the job
function Terminal.hide_current_terminal(state)
	if Utils.is_valid_win(state.winid) then
		pcall(vim.api.nvim_win_close, state.winid, true)
		state.winid = nil
	end
end

-- Resume an existing profile's terminal or create new one
function Terminal.resume_profile_terminal(state, profile_name)
	-- Get existing job and buffer for this profile
	local existing_job = state.profile_jobs[profile_name]
	local existing_buf = state.profile_buffers[profile_name]

	-- Create or reuse window
	local side = (state.config and state.config.side) or "right"
	local win = Utils.create_split_on_side(side)

	-- Apply window sizing and styling
	local size_value = nil
	local cfg_size = state.config and state.config.size or nil
	if type(cfg_size) == "string" then
		local pct = tonumber(cfg_size:match("^(%d+)%%$"))
		if pct and pct > 0 then
			if side == "bottom" then
				size_value = math.floor((vim.o.lines or 24) * (pct / 100))
			else
				size_value = math.floor((vim.o.columns or 80) * (pct / 100))
			end
		end
	elseif type(cfg_size) == "number" and cfg_size > 0 then
		size_value = cfg_size
	end

	if not size_value then
		if side == "bottom" then
			size_value = 12
		else
			size_value = 65
		end
	end

	if side == "bottom" then
		Utils.set_window_height(win, size_value)
	else
		Utils.set_window_width(win, size_value)
	end
	Utils.apply_window_look(win, side)

	-- If we have an existing buffer and job, reuse them
	if Utils.is_valid_buf(existing_buf) and Utils.is_job_running(existing_job) then
		vim.api.nvim_win_set_buf(win, existing_buf)
		state.bufnr = existing_buf
		state.jobid = existing_job
		state.winid = win
		pcall(vim.api.nvim_set_current_win, win)
		if state.config.start_insert then
			vim.cmd("startinsert")
		end
	else
		-- Create new terminal for this profile
		open_new_terminal(state, win)
	end
end

-- Switch to a different profile seamlessly
function Terminal.switch_to_profile(state, profile_name, new_config)
	-- Hide current terminal (but keep job running)
	Terminal.hide_current_terminal(state)

	-- Update config and current profile
	state.config = new_config
	local old_profile = state.current_profile
	state.current_profile = profile_name

	-- Resume or create terminal for new profile
	Terminal.resume_profile_terminal(state, profile_name)

	return true
end

-- Cleanup all background jobs (called on exit)
function Terminal.cleanup_all_jobs(state)
	for profile_name, job_id in pairs(state.profile_jobs or {}) do
		if Utils.is_job_running(job_id) then
			pcall(vim.fn.jobstop, job_id)
		end
	end
	state.profile_jobs = {}
	state.profile_buffers = {}
end

return Terminal
