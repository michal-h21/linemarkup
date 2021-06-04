local linemarkup = {}
linemarkup.active = true
linemarkup.parsers = {}

local Parser = {}
Parser.__index = Parser

local function warning(text)
  print("[linemarkup] warning: " .. text)
end

--- Add rules for parsing. Patterns should match text that follows sigil
-- Multiple patterns can be used for one sigil, add them from the most specific to 
-- the least specific. To match the whole rest of line, leave pattern empty.
-- @param pattern Lua pattern that can match additional markup from the line after sigil. It must contain at least sigil.
-- Use empty string to match the whole text
-- @param replace string that will be filled with matched text from pattern. The %1 string will contain 
-- line value if no pattern argument is provided
-- @param block_type unique name of the block
function Parser.add_rule(self, pattern, replace, block_type)
  local sigil, pattern = pattern:match("^(.)(.*)")
  local rules = self.rules
  local sigil_patterns = rules[sigil] or {}
  -- replace empty pattern with pattern that matches everything
  if pattern == "" then pattern = "(.+)" end
  self.types[block_type] = {pattern = pattern, replace = replace, block_type = block_type}
  sigil_patterns[#sigil_patterns+1] = block_type
  rules[sigil] = sigil_patterns
end

-- test if the current line matches the block type
function Parser.match_block_type(self,block_type, rest)
  local typ = self.types[block_type] or {}
  local pattern = typ.pattern or ""
  return rest:match(pattern)
end

function Parser.replace(self, block_type, rest)
  local typ = self.types[block_type] or {}
  local pattern = typ.pattern or ""
  local replace = typ.replace or ""
  return rest:gsub(pattern, replace)
end



--- replace white space around text
function Parser.trim(self, text)
  return text:gsub("^%s*", ""):gsub("%s*$", "")
end

function Parser.get_rules(self, line)
  local sigil, rest =  line:match("^%s*(.)(.+)")
  -- stop processing of the line if no sigil could be found
  if not sigil then return nil end
  -- remove unnecessary whitespace
  rest = self:trim(rest)
  return rest, self.rules[sigil]
end

-- initialize table that will be returned
function Parser.new_line(self, line)
  return {block_type = "text", line = line, value = line}
end

function Parser.parse_line(self, line)
  -- prepare result table with default values
  local result = self:new_line(line)
  -- don't process the line at all when the processing is disabled
  if not linemarkup.active then return result end
  local rest, rules = self:get_rules(line)
  -- just return the original text if there are no rules for the current sigil
  if not rules then return result end
  for _, rule in ipairs(rules) do
    if self:match_block_type(rule, rest) then
      result.value = self:replace(rule, rest)
      result.block_type = rule
      return result
    end
  end
  return result
end


function linemarkup.new_parser(name)
  local self = setmetatable({}, Parser)
  self.rules = {}
  self.types = {}
  return self
end

-- we want to keep record of used parsers 
-- in order to close environments when parsers change in the document
function linemarkup.declare_parser(name)
  if linemarkup.parsers[name] then 
    warning("Parser with name " .. name .. "already exists")
  else
    linemarkup.parsers[name] = linemarkup.new_parser()
  end
  return linemarkup.parsers[name] 
end


--- select correct parser for the current line, process it, and return transformed text
function linemarkup.process_line(line, parser_name)
  local parse = linemarkup.parsers[parser_name]
  -- just return the original text if parsing is not active or if we cannot find the parser by name
  if not parse or linemarkup.active == false then return line end
  local result = parse:parse_line(line)
  -- if result.line then
    -- print(result.line, result.value, result.block_type,tex.toks["linemarkup@currentmarkup"])
  -- end
  -- return value parser by lineparser, or the original line
  return result.value or line
end


-- print(parse:parse_line("# ahoj světe"))

return linemarkup


