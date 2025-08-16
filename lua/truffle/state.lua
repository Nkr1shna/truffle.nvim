local State = {
	bufnr = nil,
	winid = nil,
	jobid = nil, -- Legacy single job support
	config = nil,
	current_profile = nil, -- Track the active profile name
	base_config = nil, -- Store the original config without profile overrides
	profile_jobs = {}, -- Track jobids per profile: { profile_name = jobid }
	profile_buffers = {}, -- Track buffers per profile: { profile_name = bufnr }
	_commands_created = false,
	_mappings_set = {},
}

return State
