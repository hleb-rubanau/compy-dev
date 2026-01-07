-- Title: Trap Sensor
gfx = love.graphics
Rectangle = require("rectangle")

--- constants 

TRAP_PERCENT=15
CELL_SIZE=32 

colors = { -- white, black, bright, yellow, green, magenta, cyan, blue, red, with_alpha()
  bg = Color[Color.blue],
  status_panel_bg = Color[Color.bright],
  status_panel_fg = Color[Color.green],
  text = Color[Color.red],
  yellow = Color[Color.yellow],
  --field_border = {200,200,220}
  field_border = Color[Color.white]
}

-- to be initialized
rectangles = { }
state = { }
config = { }
grid = { }

function logdebug(...)
  local msg = string.format(...)
  print(msg)
end

function initPanels()
  --- base geometries and coordinates

  local screen_w, screen_h = gfx.getDimensions()

  local screen = Rectangle:new(screen_w, screen_h)

  -- leave space for console/input lines
  local ui_canvas = screen:upper(0.89)

  rectangles.main_panel   = ui_canvas:upper(0.85)
  rectangles.status_panel = ui_canvas:lower(0.15)

end 

function initGridConfig()

  local mp = rectangles.main_panel
  local trap_rate = TRAP_PERCENT / 100

  config.cols = math.floor( mp.width / CELL_SIZE )
  config.rows = math.floor( mp.height / CELL_SIZE )
  config.n_cells = config.cols * config.rows
  config.n_traps = math.ceil( config.n_cells * trap_rate )
  
end

function initGameField()

  local width = CELL_SIZE * config.cols
  local height = CELL_SIZE * config.rows

  local mp = rectangles.main_panel
  rectangles.field = mp:central( width, height )

end

function initStatusTextBox()

  local sp = rectangles.status_panel

  local textbox_height = font:getHeight() 
  local padding = ( sp.height - textbox_height ) / 2
  local textbox_width = sp.width - 2*padding

  local textbox = sp:central(textbox_width, textbox_height)
  rectangles.status_textbox = textbox
end 

--- visualisation 

function drawGameField()
  gfx.setColor(colors.field_border)
  local f = rectangles.field 

  for i = 0, config.cols do
    local border_pos_x = f.x + i*CELL_SIZE 
    gfx.line( border_pos_x, f.top, border_pos_x, f.bottom )
  end

  for j = 0 , config.rows do
    local border_pos_y = f.y + j*CELL_SIZE 
    gfx.line( f.left, border_pos_y, f.right, border_pos_y )
  end
end

function drawMainPanel()
  gfx.setColor(colors.bg)
  gfx.rectangle("fill", rectangles.main_panel:x_y_w_h() )
end 

function drawStatusPanel()
  gfx.setColor(colors.status_panel_bg)
  gfx.rectangle("fill", rectangles.status_panel:x_y_w_h() )
  gfx.setColor(colors.status_panel_fg)
  gfx.rectangle("line", rectangles.status_panel:x_y_w_h() )
end

function drawStatus(...)

  local txt = string.format(...)

  -- required to clean up anything previously written
  drawStatusPanel() 
  gfx.setColor(colors.status_panel_fg)

  -- shortcut
  local tb = rectangles.status_textbox
  logdebug("Textbox shape: ".. tb:inspect() )
  gfx.printf( txt, tb.x, tb.y, tb.width )

end

function drawInitialStatus()
  local c = config.cols
  local r = config.rows
  local n = config.n_cells
  local m = config.n_traps
  drawStatus("Grid: %s x %s ( %s cells with %s traps)",c,r,n,m)
end

-- called once
function initUI()

  initPanels()
  initGridConfig()
  initGameField()
  initStatusTextBox()

  drawMainPanel()
  drawGameField()
  drawStatusPanel()

  drawInitialStatus()
end

initUI()
