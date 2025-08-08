local M = {}

local state = {
  bufnr = nil,
  winid = nil,
  jobid = nil,
  config = nil,
  _commands_created = false,
  _mappings_set = {},
}

local DEFAULT_CONFIG = {
  width = 65,
  start_insert = true,
  create_mappings = true,
  mappings = {
    toggle = "<leader>tc",
    send_selection = "<leader>ts",
    send_file = "<leader>tf",
    send_input = "<leader>ti",
  },
}

-- Validate user-provided options; returns boolean
local function validate_opts(opts)
  opts = opts or {}

  local ok, err = pcall(vim.validate, {
    command = { opts.command, "string", true },
    width = { opts.width, "number", true },
    start_insert = { opts.start_insert, "boolean", true },
    create_mappings = { opts.create_mappings, "boolean", true },
    toggle_mapping = { opts.toggle_mapping, "string", true },
    mappings = {
      opts.mappings,
      function(m)
        if m == nil then return true end
        if type(m) ~= "table" then return false end
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
        if v == nil then return true end
        local t = type(v)
        if t == "number" then return v > 0 end
        if t == "string" then return v:match("^%d+%%$") ~= nil end
        return false
      end,
      "number > 0 or percentage string like '33%'",
    },
    side = {
      opts.side,
      function(v)
        if v == nil then return true end
        return v == "right" or v == "bottom" or v == "left"
      end,
      "one of 'right', 'bottom', 'left'",
    },
  })

  if not ok then
    vim.notify("truffle.nvim: invalid setup options: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  if type(opts.width) == "number" and opts.width <= 0 then
    vim.notify("truffle.nvim: 'width' must be > 0", vim.log.levels.ERROR)
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
  if c:find("gemini") then
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

-- Internal: ensure the terminal job is available for sending
local function ensure_job_ready()
  if not state.jobid or state.jobid <= 0 then
    vim.notify("truffle.nvim: terminal job is not running. Open the panel first.", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Internal: send string to terminal with a trailing newline if missing
local function send_to_terminal(text)
  if not ensure_job_ready() then return end
  if type(text) ~= "string" then
    vim.notify("truffle.nvim: send_text expects a string.", vim.log.levels.ERROR)
    return
  end
  local needs_newline = not (text:sub(-1) == "\n" or text:sub(-1) == "\r")
  local payload = needs_newline and (text .. "\r") or text
  pcall(vim.fn.chansend, state.jobid, payload)
end

-- Public: send plain text to the running job
function M.send_text(text)
  if text == nil then
    vim.notify("truffle.nvim: send_text requires a string.", vim.log.levels.ERROR)
    return
  end
  send_to_terminal(tostring(text))
end

-- Internal: capture current visual selection as text
local function get_visual_selection_text()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]

  -- Normalize order
  if end_line < start_line or (end_line == start_line and end_col < start_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then return "" end

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
  for _, m in ipairs(middle) do table.insert(result, m) end
  table.insert(result, last)
  return table.concat(result, "\n")
end

-- Public: send the current visual selection to the running job
function M.send_visual()
  local text = get_visual_selection_text()
  if not text or text == "" then
    vim.notify("truffle.nvim: visual selection is empty.", vim.log.levels.WARN)
    return
  end
  send_to_terminal(text)
end

-- Public: send a file's contents to the running job
function M.send_file(opts)
  opts = opts or {}
  local path = opts.path
  if not path or path == "current" then
    path = vim.api.nvim_buf_get_name(0)
  end

  if not path or path == "" then
    vim.notify("truffle.nvim: current buffer has no file path to send.", vim.log.levels.ERROR)
    return
  end

  local stat = vim.loop.fs_stat(path)
  if not stat or stat.type ~= "file" then
    vim.notify("truffle.nvim: cannot read file: " .. path, vim.log.levels.ERROR)
    return
  end

  local MAX_FILE_BYTES = 1024 * 1024 -- 1MB guard
  if stat.size and stat.size > MAX_FILE_BYTES then
    vim.notify("truffle.nvim: file too large to send (limit 1MB): " .. path, vim.log.levels.ERROR)
    return
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then
    vim.notify("truffle.nvim: failed to read file: " .. path, vim.log.levels.ERROR)
    return
  end
  local text = table.concat(lines, "\n")
  if text == "" then
    vim.notify("truffle.nvim: file is empty: " .. path, vim.log.levels.WARN)
  end
  send_to_terminal(text)
end

local function create_user_commands()
  if state._commands_created then return end

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

  state._commands_created = true
end

local function create_default_keymaps()
  local function set_map(mode, lhs, rhs, desc)
    if not lhs or lhs == "" then return end
    local key = mode .. "\0" .. lhs
    local prev = state._mappings_set[key]
    if prev and prev ~= lhs then
      pcall(vim.keymap.del, mode, prev)
    end
    if not prev then
      pcall(vim.keymap.set, mode, lhs, rhs, { desc = desc })
      state._mappings_set[key] = lhs
    end
  end

  -- Clear existing when disabled
  if not state.config.create_mappings then
    for key, lhs in pairs(state._mappings_set) do
      local mode = key:sub(1, 1)
      pcall(vim.keymap.del, mode, lhs)
      state._mappings_set[key] = nil
    end
    return
  end

  -- Back-compat: allow old `toggle_mapping`
  local mappings = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG.mappings), state.config.mappings or {})
  if state.config.toggle_mapping and state.config.toggle_mapping ~= "" then
    mappings.toggle = state.config.toggle_mapping
  end

  set_map("n", mappings.toggle, function() M.toggle() end, "Truffle: Toggle panel")
  set_map("v", mappings.send_selection, function() M.send_visual() end, "Truffle: Send selection")
  set_map("n", mappings.send_file, function() M.send_file({ path = "current" }) end, "Truffle: Send file")
  set_map("n", mappings.send_input, function()
    vim.ui.input({ prompt = "Truffle text: " }, function(input)
      if input and input ~= "" then M.send_text(input) end
    end)
  end, "Truffle: Send input text")
end

function M.setup(opts)
  opts = opts or {}

  -- Enforce mandatory command option early with clear message
  if not opts.command or opts.command == "" then
    state.config = vim.deepcopy(DEFAULT_CONFIG)
    vim.notify(
      "truffle.nvim: setup requires a 'command' option. Example: require('truffle').setup({ command = 'cursor-agent' })",
      vim.log.levels.ERROR
    )
    return
  end

  -- Validate optional fields and types; on failure, do not mutate state or create side effects
  if not validate_opts(opts) then
    return
  end

  -- Merge and apply config
  state.config = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts)

  -- Create commands only once; mappings updated idempotently
  create_user_commands()
  create_default_keymaps()
end

return M
