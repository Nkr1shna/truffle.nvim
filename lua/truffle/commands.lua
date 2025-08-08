local Commands = {}

function Commands.create_user_commands(state, api)
	if state._commands_created then
		return
	end

	pcall(vim.api.nvim_create_user_command, "TruffleToggle", function()
		api.toggle()
	end, { desc = "Toggle the Truffle terminal" })

	pcall(vim.api.nvim_create_user_command, "TruffleOpen", function()
		api.open()
	end, { desc = "Open the Truffle terminal" })

	pcall(vim.api.nvim_create_user_command, "TruffleClose", function()
		api.close()
	end, { desc = "Close the Truffle terminal" })

	pcall(vim.api.nvim_create_user_command, "TruffleFocus", function()
		api.focus()
	end, { desc = "Focus the Truffle terminal" })

	state._commands_created = true
end

return Commands
