local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end

  local content = file:read("*all")
  file:close()
  return content
end

local function data_dir()
  local data_dir = os.getenv("XDG_DATA_HOME") or os.getenv("HOME") .. '/.local/share'
  return data_dir .. '/' .. 'exit.nvim'
end

local function key_path(filename)
  return data_dir() .. "/" .. filename .. ".txt"
end

local function clear_prompt()
  vim.cmd("redraw | echo ''")
end

local function write_file(path, content)
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

local function ensure_data_dir_exists()
  local path = data_dir()
  if vim.fn.isdirectory(path) == 1 then return end
  if vim.fn.mkdir(path, "p") == 1 then return end
  error("Error creating " .. path)
end

local function input(args)
  local user_input = nil

  vim.ui.input({ prompt = args.prompt }, function(input)
    user_input = input

    clear_prompt()
    if user_input == '' then
      args.on_no_input()
    else
      args.on_input(user_input)
    end
  end)

  return user_input
end

local Module = {}

Module.includes = function(array, value)
  for _, v in ipairs(array) do
    if v == value then
      return true
    end
  end

  return false
end

Module.keys = function(table_)
  local array = {}

  for key, _ in pairs(table_) do
    table.insert(array, key)
  end

  return array
end

Module.split = function(string_, separator)
  local array = {}

  for s in string.gmatch(string_, "([^" .. separator .. "]+)") do
    table.insert(array, s)
  end

  return array
end

Module.system = function(command, error_message)
  local response = vim.fn.system(command)
  local exit_status = vim.v.shell_error
  if exit_status ~= 0 then error(error_message) end
  return vim.fn.json_decode(response)
end

Module.api_key = function(adapter_name)
  local path = key_path(adapter_name)
  local api_key = read_file(path)
  if not api_key then
    api_key = input({
      prompt = 'Enter your ' .. adapter_name .. ' API key: ',
      on_no_input = function() print("No API key provided.") end,
      on_input = function(user_input)
        ensure_data_dir_exists()
        local path = key_path(adapter_name)
        write_file(path, user_input)
      end,
    })
  end
  return api_key
end

return Module
