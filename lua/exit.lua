local utils = require 'utils'
local adapters_by_name = {
  openai = require 'openai',
  ollama = require 'ollama',
}

local function components(model_id)
  adapter_model = utils.split_once(model_id, ":")

  if #adapter_model ~= 2 then
    local model_ids = {}
    for _, adapter in ipairs(utils.keys(adapters_by_name)) do
      table.insert(model_ids, adapter .. ":MODEL")
    end
    error(model_id .. " is not a valid model id. Available model ids: " .. table.concat(model_ids, ", "))
  end

  return adapter_model[1], adapter_model[2]
end

local Module = {}

Module.set_model = function(model_id)
  adapter_name, model_name = components(model_id)

  if not utils.includes(utils.keys(adapters_by_name), adapter_name) then
    error(
      adapter_name ..
      " is not a valid adapter. Available adapters: " ..
      table.concat(utils.keys(adapters_by_name), ", ")
    )
  end

  Module.options = {
    adapter = adapters_by_name[adapter_name],
    model_name = model_name,
  }
end

Module.setup = function(config)
  if config == nil then config = {} end
  Module.set_model(config.model or '')
end

Module.prompt = function(prompt)
  if not prompt or prompt == "" then
    error("Prompt is empty; please provide a valid prompt.")
  end

  local cmd = Module.options.adapter.prompt(Module.options.model_name, prompt)
  local no_bangs = vim.fn.escape(cmd, "!") -- prevent `:!rm -rf` or `:r !rm -rf` or `w !rm -rf`
  local no_newlines = utils.escape_newlines(no_bangs) -- prevent autoexecuting the command
  local no_whitespace = utils.trim_whitespace(no_newlines)
  vim.api.nvim_feedkeys(no_whitespace, "n", {})
end

return Module

