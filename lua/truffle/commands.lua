local Commands = {}
local Utils = require("truffle.utils")

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

	-- Debug command to check current state
	pcall(vim.api.nvim_create_user_command, "TruffleDebug", function()
		local current = state.current_profile or "none"
		local has_base = state.base_config and "yes" or "no"
		local has_profiles = (state.base_config and state.base_config.profiles) and "yes" or "no"
		local terminal_open = Utils.is_valid_win(state.winid) and "yes" or "no"

		-- Get background job info
		local jobs_info = {}
		for profile_name, job_id in pairs(state.profile_jobs or {}) do
			local running = Utils.is_job_running(job_id)
			table.insert(
				jobs_info,
				"  " .. profile_name .. ": job_id=" .. job_id .. " (running=" .. (running and "yes" or "no") .. ")"
			)
		end
		local jobs_text = #jobs_info > 0 and ("\nBackground jobs:\n" .. table.concat(jobs_info, "\n"))
			or "\nBackground jobs: none"

		vim.notify(
			"truffle.nvim debug info:\n"
				.. "Current profile: "
				.. current
				.. "\n"
				.. "Has base_config: "
				.. has_base
				.. "\n"
				.. "Has profiles: "
				.. has_profiles
				.. "\n"
				.. "Terminal open: "
				.. terminal_open
				.. jobs_text,
			vim.log.levels.INFO
		)
	end, { desc = "Show Truffle debug information" })

	-- Only create the switch profile command if profiles are configured
	if state.base_config and state.base_config.profiles then
		pcall(vim.api.nvim_create_user_command, "TruffleSwitchProfile", function(cmd_opts)
			if cmd_opts.args == "" then
				-- List available profiles
				local profiles = {}
				for name, profile in pairs(state.base_config.profiles) do
					local info = name .. " (" .. profile.command .. ")"
					table.insert(profiles, info)
				end
				table.sort(profiles)
				local current = state.current_profile and (" [current: " .. state.current_profile .. "]") or ""
				vim.notify(
					"truffle.nvim: available profiles:\n" .. table.concat(profiles, "\n") .. current,
					vim.log.levels.INFO
				)
			else
				-- Parse arguments: profile_name [cwd=path]
				local args = vim.split(cmd_opts.args, "%s+")
				local profile_name = args[1]
				local opts = {}

				-- Parse optional key=value flags
				for i = 2, #args do
					local arg = args[i]
					local key, value = arg:match("^([^=]+)=(.*)$")
					if key and value then
						if key == "cwd" then
							opts.cwd = value
						else
							vim.notify("truffle.nvim: unknown option: " .. key, vim.log.levels.ERROR)
							return
						end
					else
						vim.notify(
							"truffle.nvim: invalid argument format: " .. arg .. ". Use key=value format.",
							vim.log.levels.ERROR
						)
						return
					end
				end

				if not profile_name then
					vim.notify("truffle.nvim: profile name required", vim.log.levels.ERROR)
					return
				end

				api.switch_profile(profile_name, opts)
			end
		end, {
			desc = "Switch Truffle profile (usage: profile_name [cwd=path])",
			nargs = "*",
			complete = function(arglead, cmdline, cursorpos)
				local args = vim.split(cmdline, "%s+")
				-- Remove the command name
				table.remove(args, 1)

				-- If we're completing the first argument and it doesn't contain =, complete profile names
				if #args == 0 or (#args == 1 and not arglead:match("=")) then
					if state.base_config and state.base_config.profiles then
						local profiles = {}
						for name, _ in pairs(state.base_config.profiles) do
							if name:find(arglead, 1, true) == 1 then
								table.insert(profiles, name)
							end
						end
						return profiles
					end
					return {}
				end

				-- Complete key=value options
				if arglead:match("^[^=]*$") then
					-- Completing the key part before =
					local options = { "cwd=" }
					local matches = {}
					for _, option in ipairs(options) do
						if option:find(arglead, 1, true) == 1 then
							table.insert(matches, option)
						end
					end
					return matches
				end

				-- Complete value part after =
				local key, partial_value = arglead:match("^([^=]+)=(.*)$")
				if key == "cwd" then
					-- Complete directories
					local dirs = vim.fn.getcompletion(partial_value, "dir")
					local matches = {}
					for _, dir in ipairs(dirs) do
						table.insert(matches, key .. "=" .. dir)
					end
					return matches
				end

				return {}
			end,
		})
	end

	state._commands_created = true
end

return Commands
