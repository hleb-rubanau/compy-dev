local class = require("util.class")
local assert = require("luassert")
local fmt = string.format

EditorSession = class.create(
  function(controller, press, save, mock)
    return {
      controller = controller,
      press = press,
      save = save,
      mock = mock,
    }
  end
)

function EditorSession:open(src, nb)
  self.save(src)
  self.controller:open("test.lua", src, self.save)
  local input = self.controller.input
  local buffer = self.controller:get_active_buffer()

  local srclines = string.lines(src)
  local has_trailing_nl = (srclines[#srclines] == "")
  local expected = (has_trailing_nl and src or src .. "\n")

  assert.same(
    string.lines(expected),
    buffer:get_text_content(),
    "desired content loaded"
  )
  if nb then
    if has_trailing_nl then
      assert.same(
        nb,
        buffer:get_content_length(),
        fmt("Blocks loaded: %s", nb)
      )
    else
      assert.same(
        nb + 1,
        buffer:get_content_length(),
        fmt("Blocks loaded: %s original +1 extra", nb)
      )
    end
  end
  self.input = input
  self.buffer = buffer
  return input, buffer
end

-- this helper is a bit of a dirty hack
-- so it only works reliably in block-level navigation mode!
-- (when editor multiline input buffer is not yet activated with <ESC>)
-- see also: https://github.com/compy-toys/compy/issues/117 (p.2)
function EditorSession:select_block(n, target_content)
  local s = self.buffer.selection
  local dir = (s > n) and "up" or "down"
  local steps = math.abs(s - n)
  if (not self.input:is_empty()) and (steps > 0) then
    local jumpkey = dir == "up" and "home" or "end"
    self.mock.keystroke(jumpkey, self.press)
  end
  for i = 1, steps do
    self.mock.keystroke(dir, self.press)
  end

  assert.same(
    n,
    self.buffer.selection,
    fmt("selection moved to block #%s", n)
  )
  if target_content then
    assert.same(
      string.lines(target_content),
      self.buffer:get_selected_text(),
      "selected block #%s has expected content",
      n
    )
  end
end

function EditorSession:select_and_open_block(n, target_content)
  self:select_block(n, target_content)
  self.mock.keystroke("escape", self.press)

  assert.same(n, self.buffer.loaded, fmt("loaded block #%s", n))
  if target_content then
    assert.same(
      string.lines(target_content),
      self.input:get_text(),
      "input loaded expected content (block #%s)",
      n
    )
  end
end

function EditorSession:alter_input(newtext)
  local newlines = string.lines(newtext)
  self.input:set_text(newlines)
  assert.same(newlines, self.input:get_text(), "input altered")
end

function EditorSession:submit(newtext, ctrl)
  self:alter_input(newtext)
  local keycode = ctrl and "C-return" or "return"
  self.mock.keystroke(keycode, self.press)
end
