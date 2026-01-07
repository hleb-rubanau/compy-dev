-- Title: Trap Sensor

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
ui = { }
state = { }
config = { }
grid = { }

function logdebug(...)
  local msg = string.format(...)
  print(msg)
end

gfx = love.graphics
Canvas = require("canvas")

function initPanels()
  --- base geometries and coordinates

  local screen_w, screen_h = gfx.getDimensions()

  local screen = Canvas:new(screen_w, screen_h)

  -- leave space for console/input lines
  local ui_canvas = screen:upper(0.89)

  ui.main_panel   = ui_canvas:upper(0.85)
  ui.status_panel = ui_canvas:lower(0.15)

end 

function initGridConfig()

  local cols = math.floor( ui.main_panel.width / CELL_SIZE )
  local rows = math.floor( ui.main_panel.height / CELL_SIZE )
  local n_cells = cols * rows
  local n_traps = math.ceil( n_cells * TRAP_PERCENT / 100 )
  
  config = { 
    cols = cols,
    rows = rows,
    n_cells = n_cells,
    n_traps = n_traps
  }

end

function initGameField()

  local width = CELL_SIZE * config.cols
  local height = CELL_SIZE * config.rows

  ui.field = ui.main_panel:central( width, height )

end

function initStatusTextBox()

  local sp = ui.status_panel

  local textbox_height = font:getHeight() 
  local padding = ( sp.height - textbox_height ) / 2
  local textbox_width = sp.width - 2*padding

  ui.status_textbox = sp:central(textbox_width, textbox_height)

end 

--- visualisation 

function drawGameField()
  gfx.setColor(colors.field_border)
  local f = ui.field 

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
  gfx.rectangle("fill", ui.main_panel:x_y_w_h() )
end 

function drawStatusPanel()
  gfx.setColor(colors.status_panel_bg)
  gfx.rectangle("fill", ui.status_panel:x_y_w_h() )
  gfx.setColor(colors.status_panel_fg)
  gfx.rectangle("line", ui.status_panel:x_y_w_h() )
end

function drawStatus(...)

  local txt = string.format(...)

  -- required to clean up anything previously written
  drawStatusPanel() 
  gfx.setColor(colors.status_panel_fg)

  -- shortcut
  local tb = ui.status_textbox
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
