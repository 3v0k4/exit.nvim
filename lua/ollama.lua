local utils = require 'utils'

local Module = {}

Module.name = 'ollama'

Module.default_model = 'llama3.2:3b'

Module.models = {
  Module.default_model,
  'deepseek-coder:1.3b',
  'tinydolphin:latest',
  'qwen2.5:7b',
}

local system_prompt = [[
Return only the command to be executed as a raw string, no string delimiters
wrapping it, no yapping, no markdown, no fenced code blocks, what you return
will be passed to vim directly.

Example 1: if the user asks: select abc

You return only: /abc

Example 2: If the user asks how to quit vim, you return: :q
Here is the question:
]]

-- Define appendPrompt and add it to the Module table
Module.append_prompt = function(prompt)
  if not prompt then
    error("Prompt is nil; please provide a valid prompt.")
  end
  return system_prompt .. prompt
end

Module.insert_command = function(cmd)
  -- Ensure cmd is a string and trim any whitespace
  cmd = tostring(cmd):gsub("^%s*(.-)%s*$", "%1")

  local escaped = vim.fn.escape(cmd, '\\\"')

  local no_colon = string.gsub(escaped, ":", "")

  vim.fn.input(":", no_colon)
end


Module.prompt = function(model, prompt)
  if not prompt then
    error("Prompt is nil; please provide a valid prompt.")
  end
  local data = vim.fn.json_encode({ model = model, prompt = Module.appendPrompt(prompt), stream = false })
  local command = 'curl -s -X POST http://localhost:11434/api/generate -d \'' .. data .. '\''
  print("Prompting..")
  local response = utils.system(command, 'Failed to run curl')

  -- Check if the model is an OpenAI model
  if model:match("openai") then
    -- Assuming OpenAI model returns the expected response format
    if not response.choices or #response.choices == 0 then
      error("No choices received in the response.")
    end
    return response.choices[1].message.content -- OpenAI response handling
  else
    -- Assuming Ollama model returns the response field
    if not response.response then
      error("No response received in the response.")
    end

    -- Clean up the response
    local clean_response = response.response:gsub("v:null$", "")

    -- Use the cleaned response
    require('ollama').insert_command(clean_response)
  end
end

return Module
