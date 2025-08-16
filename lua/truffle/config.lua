local DEFAULT_CONFIG = {
	-- Layout & sizing
	side = "right", -- one of: right | bottom | left
	size = nil, -- number of cols/rows or percentage string like "33%"

	-- Behavior
	start_insert = false,
	create_mappings = true,
	mappings = {
		toggle = "<leader>tc",
		send_selection = "<leader>ts",
		send_file = "<leader>tf",

		next_profile = "]c",
		prev_profile = "[c",
	},

	-- Profiles support
	profiles = nil, -- Table of { name = { command, cwd?, default? } }
}

local function validate_profile(profile)
	if type(profile) ~= "table" then
		return false, "profile must be a table"
	end

	if type(profile.command) ~= "string" or profile.command == "" then
		return false, "profile must have a non-empty 'command' field"
	end

	if profile.cwd ~= nil and type(profile.cwd) ~= "string" then
		return false, "profile 'cwd' must be a string"
	end

	if profile.env ~= nil and type(profile.env) ~= "table" and type(profile.env) ~= "string" then
		return false, "profile 'env' must be a table or string (file path)"
	end

	if profile.default ~= nil and type(profile.default) ~= "boolean" then
		return false, "profile 'default' must be a boolean"
	end

	return true
end

local function validate_opts(opts)
	opts = opts or {}

	local ok, err = pcall(vim.validate, {
		start_insert = { opts.start_insert, "boolean", true },
		create_mappings = { opts.create_mappings, "boolean", true },
		toggle_mapping = { opts.toggle_mapping, "string", true },
		cwd = { opts.cwd, "string", true },
		env = {
			opts.env,
			function(v)
				if v == nil then
					return true
				end
				return type(v) == "table" or type(v) == "string"
			end,
			"table or string (file path)",
		},
		profiles = { opts.profiles, "table", true },
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
				local valid_keys = { "toggle", "send_selection", "send_file", "next_profile", "prev_profile" }
				for k, v in pairs(m) do
					local key_valid = false
					for _, valid_key in ipairs(valid_keys) do
						if k == valid_key then
							key_valid = true
							break
						end
					end
					if not key_valid then
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
			"table with optional string fields: toggle, send_selection, send_file, next_profile, prev_profile",
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

	-- Validate profiles if provided
	if opts.profiles then
		local default_count = 0
		for name, profile in pairs(opts.profiles) do
			if type(name) ~= "string" or name == "" then
				vim.notify("truffle.nvim: profile names must be non-empty strings", vim.log.levels.ERROR)
				return false
			end

			local profile_ok, profile_err = validate_profile(profile)
			if not profile_ok then
				vim.notify("truffle.nvim: invalid profile '" .. name .. "': " .. profile_err, vim.log.levels.ERROR)
				return false
			end

			-- Count default profiles
			if profile.default then
				default_count = default_count + 1
			end
		end

		-- Ensure at most one profile is marked as default
		if default_count > 1 then
			vim.notify("truffle.nvim: only one profile can be marked as default", vim.log.levels.ERROR)
			return false
		end
	end

	-- Profiles are now required
	if not opts.profiles then
		vim.notify("truffle.nvim: setup requires 'profiles' configuration", vim.log.levels.ERROR)
		return false
	end

	return true
end

local function merge_config(opts)
	return vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts or {})
end

local function get_profile_config(config, profile_name)
	if not config.profiles or not profile_name then
		return config
	end

	local profile = config.profiles[profile_name]
	if not profile then
		return config
	end

	-- Create a copy of the config with profile settings applied
	local profile_config = vim.deepcopy(config)
	profile_config.command = profile.command
	if profile.cwd then
		profile_config.cwd = profile.cwd
	end
	if profile.env then
		if type(profile.env) == "string" then
			-- Parse env file if env is a string path
			local Utils = require("truffle.utils")
			-- Expand path with ~ and environment variables
			local expanded_path = vim.fn.expand(profile.env)
			local env, err = Utils.parse_env_file(expanded_path)
			if err then
				vim.notify(
					"truffle.nvim: failed to parse env file for profile '" .. profile_name .. "': " .. err,
					vim.log.levels.ERROR
				)
				-- Use empty env instead of failing completely
				profile_config.env = {}
			else
				profile_config.env = env
			end
		else
			-- Use env table directly
			profile_config.env = profile.env
		end
	end

	return profile_config
end

local function get_active_profile_name(config)
	if not config.profiles then
		return nil
	end

	-- Find the profile marked as default
	for name, profile in pairs(config.profiles) do
		if profile.default then
			return name
		end
	end

	-- If no default is found, return the first profile
	return next(config.profiles)
end

return {
	DEFAULT_CONFIG = DEFAULT_CONFIG,
	validate_opts = validate_opts,
	merge_config = merge_config,
	get_profile_config = get_profile_config,
	get_active_profile_name = get_active_profile_name,
}
