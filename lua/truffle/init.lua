local M = {}

local state = {
  bufnr = nil,
  winid = nil,
  jobid = nil,
  config = nil,
}

local DEFAULT_CONFIG = {
  width = 65,
  start_insert = true,
  create_mappings = true,
  toggle_mapping = "<leader>tc",
}

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function set_window_width(win, width)
  if not is_valid_win(win) then return end
  pcall(vim.api.nvim_win_set_width, win, width)
end

local function ensure_command_available(cmd)
  local first = vim.split(cmd, "%s+", { trimempty = true })[1]
  if not first or first == "" then
    return false
  end
  return vim.fn.executable(first) == 1
end

local function guess_docs_url_for_command(cmd)
  local c = (cmd or ""):lower()
  if c:find("cursor") then
    return "https://docs.cursor.com/en/cli/installation"
  end
  if c:find("crush") then
    return "https://github.com/charmbracelet/crush"
  end
  if c:find("gemini") or c:find("gemini") then
    return "https://github.com/google-gemini/gemini-cli"
  end
  if c:find("claude") or c:find("anthropic") then
    return "https://docs.anthropic.com/en/docs/claude-code/setup"
  end
  return nil
end

local function create_split_and_focus_right()
  vim.cmd("vsplit")
  vim.cmd("wincmd L")
  return vim.api.nvim_get_current_win()
end

local function open_new_terminal(win)
  -- create new buffer and start terminal
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)

  -- Keep panel buffer hidden from buffer/tab lists
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "truffle"

  local ok, job = pcall(vim.fn.termopen, state.config.command, {
    on_exit = function()
      -- keep buffer for reuse; window may be closed separately
    end,
  })

  if not ok or not job or job <= 0 then
    vim.notify("Failed to start '" .. state.config.command .. "'. Is it in your PATH?", vim.log.levels.ERROR)
    return nil, nil
  end

  if state.config.start_insert then
    vim.cmd("startinsert")
  end

  state.bufnr = buf
  state.winid = win
  state.jobid = job
  return buf, win
end

local function reopen_existing_buffer(win)
  vim.api.nvim_win_set_buf(win, state.bufnr)

  -- Re-assert unlisted status in case user/plugins changed it
  if is_valid_buf(state.bufnr) then
    vim.bo[state.bufnr].buflisted = false
  end

  if state.config.start_insert then
    vim.cmd("startinsert")
  end
  state.winid = win
  return state.bufnr, win
end

function M.open()
  -- If already visible, focus it
  if is_valid_win(state.winid) then
    pcall(vim.api.nvim_set_current_win, state.winid)
    return
  end

  -- Require a command to be configured
  if not state.config or not state.config.command or state.config.command == "" then
    vim.notify(
      "truffle.nvim: 'command' option is required. Set it via require('truffle').setup({ command = '<your-cli>' }).",
      vim.log.levels.ERROR
    )
    return
  end

  -- Ensure command is present; if missing, notify with helpful link
  if not ensure_command_available(state.config.command) then
    local url = guess_docs_url_for_command(state.config.command)
    local msg = "Command not found: '" .. state.config.command .. "'. Install it or change the configured command."
    if url then
      msg = msg .. " See: " .. url
    end
    vim.notify("truffle.nvim: " .. msg, vim.log.levels.ERROR)
    return
  end

  local win = create_split_and_focus_right()
  set_window_width(win, state.config.width)

  if is_valid_buf(state.bufnr) then
    reopen_existing_buffer(win)
  else
    open_new_terminal(win)
  end
end

function M.close()
  if is_valid_win(state.winid) then
    pcall(vim.api.nvim_win_close, state.winid, true)
  end
  state.winid = nil
end

function M.toggle()
  if is_valid_win(state.winid) then
    M.close()
  else
    M.open()
  end
end

function M.focus()
  if is_valid_win(state.winid) then
    pcall(vim.api.nvim_set_current_win, state.winid)
  else
    M.open()
  end
end

local function create_user_commands()
  pcall(vim.api.nvim_create_user_command, "TruffleToggle", function()
    M.toggle()
  end, { desc = "Toggle the Truffle terminal" })

  pcall(vim.api.nvim_create_user_command, "TruffleOpen", function()
    M.open()
  end, { desc = "Open the Truffle terminal" })

  pcall(vim.api.nvim_create_user_command, "TruffleClose", function()
    M.close()
  end, { desc = "Close the Truffle terminal" })

  pcall(vim.api.nvim_create_user_command, "TruffleFocus", function()
    M.focus()
  end, { desc = "Focus the Truffle terminal" })
end

local function create_default_keymaps()
  if not state.config.create_mappings then return end
  local mapping = state.config.toggle_mapping or DEFAULT_CONFIG.toggle_mapping
  pcall(vim.keymap.set, "n", mapping, function()
    M.toggle()
  end, { desc = "Truffle: Toggle panel" })
end

function M.setup(opts)
  opts = opts or {}

  -- Enforce mandatory command option
  if not opts.command or opts.command == "" then
    state.config = vim.deepcopy(DEFAULT_CONFIG)
    vim.notify(
      "truffle.nvim: setup requires a 'command' option. Example: require('truffle').setup({ command = 'cursor-agent' })",
      vim.log.levels.ERROR
    )
    return
  end

  state.config = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts)
  create_user_commands()
  create_default_keymaps()
end

return M
