local DEFAULT_CONFIG = {
	-- Layout & sizing
	side = "right", -- one of: right | bottom | left
	size = nil, -- number of cols/rows or percentage string like "33%"

	-- Window/buffer polish
	buffer_name = "[Truffle]",
	buflisted = false,

	-- Behavior
	start_insert = true,
	create_mappings = true,
	mappings = {
		toggle = "<leader>tc",
		send_selection = "<leader>ts",
		send_file = "<leader>tf",
		send_input = "<leader>ti",
	},
}

local function validate_opts(opts)
	opts = opts or {}

	local ok, err = pcall(vim.validate, {
		command = { opts.command, "string", true },
		start_insert = { opts.start_insert, "boolean", true },
		create_mappings = { opts.create_mappings, "boolean", true },
		toggle_mapping = { opts.toggle_mapping, "string", true },
		buffer_name = { opts.buffer_name, "string", true },
		buflisted = { opts.buflisted, "boolean", true },
		mappings = {
			opts.mappings,
			function(m)
				if m == nil then
					return true
				end
				if type(m) ~= "table" then
					return false
				end
				local ok_types = true
				for k, v in pairs(m) do
					if k ~= "toggle" and k ~= "send_selection" and k ~= "send_file" and k ~= "send_input" then
						ok_types = false
						break
					end
					if v ~= nil and type(v) ~= "string" then
						ok_types = false
						break
					end
				end
				return ok_types
			end,
			"table with optional string fields: toggle, send_selection, send_file, send_input",
		},
		size = {
			opts.size,
			function(v)
				if v == nil then
					return true
				end
				local t = type(v)
				if t == "number" then
					return v > 0
				end
				if t == "string" then
					return v:match("^%d+%%$") ~= nil
				end
				return false
			end,
			"number > 0 or percentage string like '33%'",
		},
		side = {
			opts.side,
			function(v)
				if v == nil then
					return true
				end
				return v == "right" or v == "bottom" or v == "left"
			end,
			"one of 'right', 'bottom', 'left'",
		},
	})

	if not ok then
		vim.notify("truffle.nvim: invalid setup options: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	if type(opts.toggle_mapping) == "string" and opts.toggle_mapping == "" then
		vim.notify("truffle.nvim: 'toggle_mapping' cannot be empty", vim.log.levels.ERROR)
		return false
	end

	if type(opts.command) == "string" and opts.command == "" then
		vim.notify("truffle.nvim: setup requires a non-empty 'command' option.", vim.log.levels.ERROR)
		return false
	end

	return true
end

local function merge_config(opts)
	return vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts or {})
end

return {
	DEFAULT_CONFIG = DEFAULT_CONFIG,
	validate_opts = validate_opts,
	merge_config = merge_config,
}
