local utils = require 'utils'

local Module = {}

Module.name = 'openai'

Module.default_model = 'gpt-3.5-turbo'

Module.models = {
  Module.default_model,
  'gpt-4',
  'gpt-4-turbo',
  'gpt-4o',
}

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
      role = 'system',
      content = system_prompt
    },
    {
      role = 'user',
      content = prompt
    }
  }
end

Module.prompt = function(model, prompt)
  local api_key = utils.api_key(Module.name)
  local data = vim.fn.json_encode({ model = model, messages = messages(prompt), max_tokens = 100 })
  local command = 'curl -s -X POST https://api.openai.com/v1/chat/completions' ..
    ' -H "Content-Type: application/json"' ..
    ' -H "Authorization: Bearer ' .. api_key .. '"' ..
    ' -d ' .. vim.fn.shellescape(data)
  print("Prompting..")
  local response = utils.system(command, 'Failed to run curl')
  if response.error then error(response.error.message) end
  return response.choices[1].message.content -- by default only one choice is returned
end

return Module
