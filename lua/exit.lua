local utils = require 'utils'
local adapters_by_name = {
  openai = require 'openai',
}

local function components(model_id)
  adapter_model = utils.split(model_id, ":")

  if #adapter_model ~= 2 then
    local model_ids = {}
    for _, adapter in ipairs(utils.keys(adapters_by_name)) do
      for _, model in ipairs(adapters_by_name[adapter].models) do
        table.insert(model_ids, adapter .. ":" .. model)
      end
    end
    error(model_id .. " is not a valid model id. Available model ids: " .. table.concat(model_ids, ", "))
  end

  return adapter_model[1], adapter_model[2]
end

local Module = {}

Module.set_model = function(model_id)
  adapter_name, model_name = components(model_id)

  if not utils.includes(utils.keys(adapters_by_name), adapter_name) then
    error(adapter_name .. " is not a valid adapter. Available adapters: " .. table.concat(utils.keys(adapters_by_name), ", "))
  end

  adapter = adapters_by_name[adapter_name]
  if not utils.includes(adapter.models, model_name) then
    error(model_name .. " is not a valid model. Available models: " .. table.concat(adapter.models, ", "))
  end

  Module.options = {
    adapter = adapter,
    model_name = model_name,
  }
end

Module.setup = function(config)
  if config == nil then config = {} end
  Module.set_model(config.model or '')
end

Module.prompt = function(prompt)
  local cmd = Module.options.adapter.prompt(Module.options.model_name, prompt)
  local escaped = vim.fn.escape(cmd, '\\\"')
  vim.api.nvim_feedkeys(escaped, "n", {})
end

return Module
