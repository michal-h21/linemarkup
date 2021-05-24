
local linemarkup = {}

local Parser = {}
Parser.__index = Parser

--- Add rules for parsing. Patterns should match text that follows sigil
-- Multiple patterns can be used for one sigil, add them from the most specific to 
-- the least specific. To match the whole rest of line, leave pattern empty.
-- @param sigil first character of the rule
-- @param pattern Lua pattern that can match additional markup from the line after sigil. 
-- Use empty string to match the whole text
-- @param replace string that will be filled with matched text from pattern. %1
function Parser.add_rule(self, sigil, pattern, replace)
  local rules = self.rules
  local sigil_patterns = rules[sigil] or {}
  -- replace empty pattern with pattern that matches everything
  if pattern == "" then pattern = "(.+)" end
  sigil_patterns[#sigil_patterns+1] = {pattern = pattern, replace = replace}
  rules[sigil] = sigil_patterns
end

--- replace white space around text
function Parser.trim(self, text)
  return text:gsub("^%s*", ""):gsub("%s*$", "")
end

function Parser.parse_line(self, line)
  local sigil, rest =  line:match("^%s*(.)(.+)")
  if not sigil then return line end
  -- remove unnecessary whitespace
  rest = self:trim(rest)
  local rules = self.rules[sigil]
  -- just return the original text if we cannot 
  if not rules then return line end
  for _, rule in ipairs(rules) do
    local pattern = rule.pattern
    if rest:match(pattern) then
      local result = rest:gsub(pattern, rule.replace)
      -- always return orignal text if the matching process fails
      return result or line
    end
  end
  return line
end


function linemarkup.new_parser()
  local self = setmetatable({}, Parser)
  self.rules = {}
  return self
end


-- print(parse:parse_line("# ahoj světe"))

return linemarkup


