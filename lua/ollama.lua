local utils = require 'utils'

local Module = {}

Module.name = 'ollama'

local system_prompt = [[
Return only the command to be executed as a raw string, no string delimiters
wrapping it, no yapping, no markdown, no fenced code blocks, one line, what you return
will be passed to vim directly.

Example 1: if the user asks: select abc

You return only: /abc

Example 2: If the user asks how to quit vim, you return: :q
Here is the question:
]]

Module.prompt = function(model, prompt)
  local data = vim.fn.json_encode({ model = model, prompt = system_prompt .. prompt, stream = false })
  local command = 'curl -s -X POST http://localhost:11434/api/generate -d \'' .. data .. '\''
  print("Prompting " .. Module.name .. ":" .. model .. "..")
  local response = utils.system(command, 'Failed to run curl: Is `ollama serve` running?')
  if response.error then error(response.error) end -- If model is not available
  return response.response
end

return Module

