local Selection = {}

local function in_visual_mode()
	local m = vim.fn.mode()
	return m == "v" or m == "V" or m == "\22"
end

function Selection.get_visual_selection_text()
	local srow, scol, erow, ecol

	if in_visual_mode() then
		-- Use current visual start ('v') and the current cursor
		local vpos = vim.fn.getpos("v") -- {bufnum, lnum (1-based), col (1-based), off}
		local cur = vim.api.nvim_win_get_cursor(0) -- {lnum (1-based), col (0-based)}
		srow = vpos[2]
		scol = vpos[3] - 1
		erow = cur[1]
		ecol = cur[2]
	else
		-- Fallback to last visual selection marks
		local s = vim.api.nvim_buf_get_mark(0, "<") -- {lnum (1-based), col (0-based)}
		local e = vim.api.nvim_buf_get_mark(0, ">")
		srow, scol = s[1], s[2]
		erow, ecol = e[1], e[2]
	end

	if not srow or srow == 0 or not erow or erow == 0 then
		return ""
	end

	if erow < srow or (erow == srow and ecol < scol) then
		srow, erow = erow, srow
		scol, ecol = ecol, scol
	end

	-- nvim_buf_get_text takes 0-based rows; end_col is exclusive
	local text = vim.api.nvim_buf_get_text(0, srow - 1, scol, erow - 1, ecol + 1, {})
	if not text or #text == 0 then
		return ""
	end
	return table.concat(text, "\n")
end

return Selection
