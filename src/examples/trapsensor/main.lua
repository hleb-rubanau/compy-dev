-- Title: Trap Sensor

Canvas = require("canvas")

gfx = love.graphics
screen_w, screen_h = gfx.getDimensions()

screen = Canvas:new(screen_w, screen_h)

-- lower 10% are occupied by console/input line, 
-- which stays on top of any drawing 
-- TBD: figure out how to use or erase this line
-- for now we reduce the logical screen to 90% of physical one
screen=screen:top(0.89)

main_panel   = screen:top(0.85)
status_panel = screen:bottom(0.15)

colors = { -- white, black, bright, yellow, green, magenta, cyan, blue, red, with_alpha()
  bg = Color[Color.blue],
  status_panel_bg = Color[Color.bright],
  status_panel_fg = Color[Color.green],
  text = Color[Color.red],
  yellow = Color[Color.yellow],
}

function logdebug(msg)
  print(msg)
  --drawText(msg)
end

function drawBackground()
  gfx.setColor(colors.bg)
  gfx.rectangle("fill", main_panel:x_y_w_h() )
  gfx.setColor(colors.status_panel_bg)
  gfx.rectangle("fill", status_panel:x_y_w_h() )
end

function drawText(txt)
  
 
  -- calculate textbox geometry and padding

  -- text is v-centered, so its upper edge is..
  -- above v-center by 0.5 of text height (font height)
  local font_h = font:getHeight() 
  local box_y = status_panel.mid_y   - ( font_h*0.5 )
  
  -- font-size determines vertical padding
  -- horizontal padding would be the same (for visual balance)
  local padding = box_y - status_panel.start_y

  -- apply padding horizontally
  local box_x = status_panel.start_x + padding
  local box_w = status_panel.width - (2*padding)

  print( "Screen: " .. screen:inspect() )
  print( "Main panel: " .. main_panel:inspect() )
  print( "Status panel: " .. status_panel:inspect() )

  print( string.format("Writing at: x=%s, y=%s, wrap=%s, (font_size=%s)", sx, sy, textbox_width, font_size) )  

  gfx.setColor(colors.status_panel_bg)
  gfx.rectangle("fill", status_panel:x_y_w_h() )

  gfx.setColor(colors.status_panel_fg)
  gfx.rectangle("line", status_panel:x_y_w_h() )
  gfx.printf( txt, box_x, box_y, box_w )

  -- gfx.rectangle("line", box_x, box_y, box_w, font_h )
  -- gfx.setColor(colors.yellow)
  -- gfx.line( status_panel.x, status_panel.ey-5, status_panel.ex, status_panel.ey-5 )
end


drawBackground()
drawText("Hello, world")

