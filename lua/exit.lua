local utils = require 'utils'
local adapters_by_name = {
  openai = require 'openai',
  ollama = require 'ollama',
}

local function components(model_id)
  local adapter_name, model_name

  if model_id:find("ollama") then
    adapter_name = "ollama"
    model_name = model_id:match(":(.*)") or model_id -- Allows "llama3.2:3b"
  else
    local adapter_model = utils.split(model_id, ":")

    if #adapter_model ~= 2 then
      local model_ids = {}
      for _, adapter in ipairs(utils.keys(adapters_by_name)) do
        for _, model in ipairs(adapters_by_name[adapter].models) do
          table.insert(model_ids, adapter .. ":" .. model)
        end
      end
      error(model_id .. " is not a valid model id. Available model ids: " .. table.concat(model_ids, ", "))
    end

    adapter_name = adapter_model[1]
    model_name = adapter_model[2]
  end

  return adapter_name, model_name
end

local Module = {}

Module.set_model = function(model_id)
  local adapter_name, model_name

  -- If the model_id starts with "openai:", extract both parts
  if model_id:match("^openai:") then
    adapter_name, model_name = components(model_id)
  else
    -- Otherwise, assume it's an Ollama model and assign "ollama" as the adapter name
    adapter_name = "ollama"
    model_name = model_id
  end

  -- Check if the adapter is valid
  if not utils.includes(utils.keys(adapters_by_name), adapter_name) then
    error(adapter_name ..
      " is not a valid adapter. Available adapters: " .. table.concat(utils.keys(adapters_by_name), ", "))
  end

  local adapter = adapters_by_name[adapter_name]

  -- Check if the model is valid
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
  if not prompt or prompt == "" then
    error("No prompt provided. Please specify a prompt to continue.")
  end

  local cmd = Module.options.adapter.prompt(Module.options.model_name, prompt)
  local escaped = vim.fn.escape(cmd, '\\\"')
  if Module.options.adapter == 'ollama' then
    return
  end
  if Module.options.adapter == 'openai' then
    vim.api.nvim_feedkeys(escaped, "n", true)
  end
end

return Module

