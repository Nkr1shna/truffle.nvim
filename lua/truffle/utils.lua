local Utils = {}

function Utils.is_valid_win(win)
	return win and vim.api.nvim_win_is_valid(win)
end

function Utils.is_valid_buf(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

function Utils.set_window_width(win, width)
	if not Utils.is_valid_win(win) then
		return
	end
	pcall(vim.api.nvim_win_set_width, win, width)
end

function Utils.ensure_command_available(cmd)
	local first = vim.split(cmd, "%s+", { trimempty = true })[1]
	if not first or first == "" then
		return false
	end
	return vim.fn.executable(first) == 1
end

function Utils.guess_docs_url_for_command(cmd)
	local c = (cmd or ""):lower()
	if c:find("cursor") then
		return "https://docs.cursor.com/en/cli/installation"
	end
	if c:find("crush") then
		return "https://github.com/charmbracelet/crush"
	end
	if c:find("gemini") then
		return "https://github.com/google-gemini/gemini-cli"
	end
	if c:find("claude") or c:find("anthropic") then
		return "https://docs.anthropic.com/en/docs/claude-code/setup"
	end
	return nil
end

function Utils.create_split_and_focus_right()
	vim.cmd("vsplit")
	vim.cmd("wincmd L")
	return vim.api.nvim_get_current_win()
end

return Utils
