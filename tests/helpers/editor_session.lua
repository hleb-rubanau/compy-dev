local class = require('util.class')
local assert = require('luassert')
local fmt = string.format 

EditorSession = class.create( 
  function(controller, press, save, mock) 
    return { controller=controller, 
             press=press, 
             save=save, 
             mock=mock } 
  end
)

function EditorSession:open(src, nb)
  self.controller:open("test.lua", src, self.save)
  local input = self.controller.input
  local buffer = self.controller:get_active_buffer()
  local cont = buffer:get_text_content()
  assert.same(string.lines(src.."\n"), 
              buffer:get_text_content(),
              "desired content loaded")
  if nb then
    assert.same(nb+1, 
                buffer:get_content_length(),
                fmt("Blocks loaded: %s original +1 extra", nb)
               )
  end
  self.input = input
  self.buffer = buffer
  return input, buffer
end

function EditorSession:select_block(n, target_content)
  local s = self.buffer.selection
  local dir = (s > n) and "up" or "down"
  local step = (s > n) and -1 or 1

  for i = s, n, step do
    self.mock.keystroke(dir, self.press)
  end

  assert.same(n, self.buffer.selection,
              fmt("selection moved to block #%s",n))
  if target_content then
    assert.same(string.lines(target_content),
                self.buffer:get_selected_text(),
                "selected block #%s has expected content", n)
  end
end

function EditorSession:select_and_open_block(n, target_content)
  self:select_block(n, target_content)
  self.mock.keystroke('escape', self.press)

  assert.same(n, self.buffer.loaded, fmt("loaded block #%s", n))
  if target_content then
    assert.same(string.lines(target_content),
                self.input:get_text(),
                "input loaded expected content (block #%s)", n)
  end
end

function EditorSession:alter_input(newtext)
  local newlines = string.lines(newtext)
  self.input:set_text(newlines)
  assert.same( newlines, self.input:get_text(), "input altered")
end
