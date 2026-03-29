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
  return input, buffer
end
