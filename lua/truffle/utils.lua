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
	-- Backward-compat shim; prefer create_split_on_side("right")
	return Utils.create_split_on_side("right")
end

function Utils.create_split_on_side(side)
	local which = side or "right"
	if which == "bottom" then
		vim.cmd("split")
		vim.cmd("wincmd J")
	elseif which == "left" then
		vim.cmd("vsplit")
		vim.cmd("wincmd H")
	else -- "right"
		vim.cmd("vsplit")
		vim.cmd("wincmd L")
	end
	return vim.api.nvim_get_current_win()
end

-- Detect if a job is still running. jobwait returns -1 for running jobs.
function Utils.is_job_running(jobid)
	if not jobid or jobid <= 0 then
		return false
	end
	local res = vim.fn.jobwait({ jobid }, 0)
	local code = res and res[1] or nil
	return code == -1
end

function Utils.set_window_height(win, height)
	if not Utils.is_valid_win(win) then
		return
	end
	pcall(vim.api.nvim_win_set_height, win, height)
end

function Utils.apply_window_look(win, side)
	if not Utils.is_valid_win(win) then
		return
	end
	local ok = pcall(function()
		local wo = vim.wo[win]
		if not wo then
			return
		end
		wo.number = false
		wo.relativenumber = false
		wo.signcolumn = "no"
		wo.foldcolumn = "0"
		wo.list = false
		if side == "bottom" then
			wo.winfixheight = true
		else
			wo.winfixwidth = true
		end
	end)
	if not ok then
		-- ignore across versions
	end
end

function Utils.parse_env_file(filepath)
	if not filepath or filepath == "" then
		return {}
	end

	-- Ensure it's a .env file
	if not filepath:match("%.env$") then
		return {}, "Only .env files are supported"
	end

	-- Check if file exists
	local file = io.open(filepath, "r")
	if not file then
		return {}, "File not found: " .. filepath
	end

	local env = {}
	local line_num = 0

	for line in file:lines() do
		line_num = line_num + 1
		-- Skip empty lines and comments
		line = line:match("^%s*(.-)%s*$") -- trim whitespace
		if line ~= "" and not line:match("^#") then
			-- Parse KEY=VALUE format
			local key, value = line:match("^([^=]+)=(.*)$")
			if key and value then
				key = key:match("^%s*(.-)%s*$") -- trim key
				-- Handle quoted values
				if value:match('^".*"$') then
					value = value:sub(2, -2) -- remove quotes
				elseif value:match("^'.*'$") then
					value = value:sub(2, -2) -- remove quotes
				end
				env[key] = value
			else
				file:close()
				return {}, "Invalid .env format at line " .. line_num .. ": " .. line
			end
		end
	end

	file:close()
	return env
end

return Utils
