local Keymaps = {}

local function apply_mapping(state, action, mode, lhs, rhs, desc)
	if not lhs or lhs == "" then
		return
	end
	local previous = state._mappings_set[action]
	if previous and (previous.lhs ~= lhs or previous.mode ~= mode) then
		pcall(vim.keymap.del, previous.mode, previous.lhs)
	end
	if not previous or previous.lhs ~= lhs or previous.mode ~= mode then
		pcall(vim.keymap.set, mode, lhs, rhs, { desc = desc })
		state._mappings_set[action] = { mode = mode, lhs = lhs }
	end
end

function Keymaps.create_default_keymaps(state, api, default_mappings)
	if not state.config.create_mappings then
		for _, rec in pairs(state._mappings_set) do
			if rec and rec.mode and rec.lhs then
				pcall(vim.keymap.del, rec.mode, rec.lhs)
			end
		end
		state._mappings_set = {}
		return
	end

	local mappings = vim.tbl_deep_extend("force", vim.deepcopy(default_mappings or {}), state.config.mappings or {})
	if state.config.toggle_mapping and state.config.toggle_mapping ~= "" then
		mappings.toggle = state.config.toggle_mapping
	end

	apply_mapping(state, "toggle", "n", mappings.toggle, function()
		api.toggle()
	end, "Truffle: Toggle panel")

	apply_mapping(state, "send_selection", "x", mappings.send_selection, function()
		api.send_visual()
	end, "Truffle: Send selection")

	apply_mapping(state, "send_file", "n", mappings.send_file, function()
		api.send_file({ path = "current" })
	end, "Truffle: Send file")

	-- Profile cycling keymaps (only if profiles are configured)
	if state.base_config and state.base_config.profiles then
		apply_mapping(state, "next_profile", "n", mappings.next_profile, function()
			api.next_profile()
		end, "Truffle: Next profile")

		apply_mapping(state, "prev_profile", "n", mappings.prev_profile, function()
			api.prev_profile()
		end, "Truffle: Previous profile")
	end
end

return Keymaps
