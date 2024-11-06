local utils = require 'utils'

local Module = {}

Module.name = 'anthropic'

local system_prompt = [[
Return only the command to be executed as a raw string, no string delimiters
wrapping it, no yapping, no markdown, no fenced code blocks, what you return
will be passed to vim directly.

For example, if the user asks: select abc

You return only: /abc
]]

local function messages(prompt)
  return {
    {
      role = 'user',
      content = prompt
    }
  }
end

Module.prompt = function(model, prompt)
  local api_key = utils.api_key(Module.name)
  local data = vim.fn.json_encode({ model = model, system = system_prompt, messages = messages(prompt), max_tokens = 100 })
  local command = 'curl -s -X POST https://api.anthropic.com/v1/messages' ..
    ' -H "content-type: application/json"' ..
    ' -H "x-api-key: ' .. api_key .. '"' ..
    ' -H "anthropic-version: 2023-06-01"' ..
    ' -d ' .. vim.fn.shellescape(data)
  print("Prompting " .. Module.name .. ":" .. model .. "..")
  local response = utils.system(command, 'Failed to run curl')
  if response.error then error(response.error.message) end -- Among others, if model is not available
  return response.content[1].text
end

return Module
