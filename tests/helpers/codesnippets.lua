--- @param name string
--- @param num_lines integer? defaults to 3; must be at least 3
--- @return string
function mock_func_snippet(name, num_lines)
  num_lines = num_lines or 3
  assert(num_lines >= 3, "minimum number of lines is 3")

  local lines = {}

  lines[#lines + 1] = string.format("function %s()", name)
  lines[#lines + 1] = string.format(
    '  print("called %s(), a function of %d lines")',
    name,
    num_lines
  )

  for i = 1, num_lines - 3 do
    lines[#lines + 1] = string.format("  -- line %d", i)
  end

  lines[#lines + 1] = "end"

  return string.unlines(lines)
end

--- @param ... string
--- @return string
--- @return { pos: integer, len: integer, start: integer,
---   ["end"]: integer }[]
function snippets_to_code(...)
  local snippets = { ... }
  local metadata = {}
  local cursor = 0

  for i, snippet in ipairs(snippets) do
    cursor = cursor + 1
    local slines = string.lines(snippet)
    metadata[#metadata + 1] = {
      pos = i,
      len = #slines,
      start = cursor,
      ["end"] = cursor + #slines,
    }
    cursor = cursor + #slines - 1
  end

  return string.unlines(snippets), metadata
end
