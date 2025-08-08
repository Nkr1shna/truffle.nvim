local Utils = require("truffle.utils")
local Selection = require("truffle.selection")

local Terminal = {}

local termclose_group = vim.api.nvim_create_augroup("TruffleTermClose", { clear = false })

local function setup_termclose_autocmd(state, buf)
	pcall(vim.api.nvim_clear_autocmds, { group = termclose_group, buffer = buf })
	vim.api.nvim_create_autocmd("TermClose", {
		group = termclose_group,
		buffer = buf,
		callback = function()
			state.jobid = nil
			pcall(vim.notify, "truffle.nvim: terminal process exited", vim.log.levels.INFO)
		end,
	})
end

local function start_job_in_current_buf(state)
	local ok, job = pcall(vim.fn.jobstart, { state.config.command }, { term = true })
	if not ok or not job or job <= 0 then
		vim.notify("Failed to start '" .. state.config.command .. "'. Is it in your PATH?", vim.log.levels.ERROR)
		return nil
	end
	state.jobid = job
	setup_termclose_autocmd(state, vim.api.nvim_get_current_buf())
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

	local win = Utils.create_split_and_focus_right()
	Utils.set_window_width(win, state.config.width)

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

function Terminal.send_text(state, text)
	if text == nil then
		vim.notify("truffle.nvim: send_text requires a string.", vim.log.levels.ERROR)
		return
	end
	send_to_terminal(state, tostring(text))
end

function Terminal.send_visual(state)
	ensure_panel_visible_and_focus_insert(state)
	local text = Selection.get_visual_selection_text()
	if not text or text == "" then
		vim.notify("truffle.nvim: visual selection is empty.", vim.log.levels.WARN)
		return
	end
	send_to_terminal(state, text)
end

function Terminal.send_file(state, opts)
	opts = opts or {}
	local bufnr = vim.api.nvim_get_current_buf()
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	table.insert(buffer_lines, "")
	send_to_terminal(state, buffer_lines)
end

return Terminal
