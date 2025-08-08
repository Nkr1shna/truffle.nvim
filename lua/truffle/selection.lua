local Selection = {}

function Selection.get_visual_selection_text()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	if end_line < start_line or (end_line == start_line and end_col < start_col) then
		start_line, end_line = end_line, start_line
		start_col, end_col = end_col, start_col
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if #lines == 0 then
		return ""
	end

	if #lines == 1 then
		local line = lines[1]
		return string.sub(line, start_col, end_col)
	end

	local first = string.sub(lines[1], start_col)
	local last = string.sub(lines[#lines], 1, end_col)
	local middle = {}
	if #lines > 2 then
		for i = 2, #lines - 1 do
			table.insert(middle, lines[i])
		end
	end

	local result = { first }
	for _, m in ipairs(middle) do
		table.insert(result, m)
	end
	table.insert(result, last)
	return table.concat(result, "\n")
end

return Selection
