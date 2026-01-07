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
  field_border = Color[Color.white],
  cell_not_revealed_bg = { 0.5, 0.5, 0.5 },
  --cell_revealed_bg = { 0.25, 0.25, 0.25 },
  cell_revealed_bg = Color[Color.green],
  cell_blown_bg = Color[Color.red],
  cell_flagged_bg = Color[Color.yellow],
  cell_trap_fg = Color[Color.black],
  --cell_flagged_fg = { 1, 0.6, 0 }, -- orange
  cell_flagged_fg = Color[Color.red], 
  --cell_default_fg = Color[Color.blue],
  cell_default_fg = Color[Color.cyan],
  cell_revealed_fg_1 = Color[Color.white],
  --cell_revealed_fg_2 = Color[Color.cyan],
  cell_revealed_fg_2 = Color[Color.black],
  cell_revealed_fg_3 = Color[Color.magenta],
  cell_revealed_fg_4 = Color[Color.red]
}

fonts = {
  status = gfx.newFont(32),
  cell   = gfx.newFont(28)
} 

-- to be initialized
rectangles = { }
state = { }
config = { }
grid = { }
counters = { }

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
  gfx.setFont(fonts.status) 

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

function newCell() 

  local cell = {
    revealed = false,
    flagged = false,
    exposed = false,
    trap = nil,
    blown = false,
    traps_around = 0,
    protected = false
  }
  return cell
end


function flowInitGrid() 
  grid = {}
  for i = 1, config.cols do
    local col = {}
    for j = 1, config.rows do
      col[j] = newCell()
    end
    grid[i] = col
  end
end

-- testing all displayable combinations
function mockPlacement()
  
  for i = 1, 10 do -- 0..8 neighbours and mine
    for j = 1, 4 do -- untouched, flagged, revealed, exposed

      local cell = grid[i][j]
      if i <= 9 then
        cell.traps_around = i-1
      else 
        cell.trap = true
      end

      if j == 2 then
        cell.flagged = true
      elseif j==3 then
        cell.revealed = true
        if cell.trap then
          cell.blown = true
        end
      elseif j==4 then
        cell.exposed = true
      end

    end
  end
end

function flowInit()
  state.status = 'ready'
  state.result = nil
  state.started = nil

  counters.revealed = 0
  counters.seconds =  0
  counters.clicks = 0

  flowInitGrid()

  mockPlacement() -- for display testing
end

function redrawStatus()
  if (state.status == 'ready') then
    drawStatus("Click on any cell to start...")
  else
  end
end 

function getCellRectangle(i,j)
  local field = rectangles.field
  local cell_x = field.x + (i-1)*CELL_SIZE
  local cell_y = field.y + (j-1)*CELL_SIZE

  return field:new( cell_x, cell_y, CELL_SIZE, CELL_SIZE )

end

function getCellBackgroundColor(cell) 

  if cell.blown then
    return colors.cell_blown
  elseif cell.revealed then
    return colors.cell_revealed
  else
    return colors.cell_hidden
  end

end

function writeCellLabel(canvas, content, fgColor)
  gfx.setColor( fgColor )
  gfx.setFont( fonts.cell )
  local fontHeight = fonts.cell:getHeight()
  local text_y = canvas.mid_y - (fontHeight/ 2 )
  gfx.printf( content, canvas.x, text_y, canvas.w, 'center' )
end


function renderCell(canvas, bgcolor, fgcolor, content)
  gfx.setColor( bgcolor )
  gfx.rectangle('fill', canvas:x_y_w_h() )
  gfx.setColor( colors.field_border )
  gfx.rectangle('line', canvas:x_y_w_h() )

  if content then
    if type(content) == 'function' then
      content( canvas )
    else 
      writeCellLabel( canvas, content, fgcolor )
    end
  end
end

function getCellBackgroundColor(cell)
  if cell.flagged then
    return colors.cell_flagged_bg
  elseif cell.blown then
    return colors.cell_blown_bg
  elseif cell.revealed then
    return colors.cell_revealed_bg
  else
    return colors.cell_not_revealed_bg
  end
end

function getCellForegroundColor(cell)
  if cell.flagged then
    return colors.cell_flagged_fg
  elseif cell.trap then
    return colors.cell_trap_fg
  else
    if cell.traps_around >= 4 then
      return colors.cell_revealed_fg_4
    elseif cell.traps_around == 3 then
      return colors.cell_revealed_fg_3
    elseif cell.traps_around == 2 then
      return colors.cell_revealed_fg_2
    elseif cell.traps_around == 1 then
      return colors.cell_revealed_fg_1
    else
      return colors.cell_default_fg
    end
  end
end

function getCellDisplayContent(cell)
  local is_exposed_trap = cell.trap and cell.exposed

  if cell.blown then
    return "X"
  elseif is_exposed_trap then
    return '*'
  elseif cell.flagged then
    return '?'
  elseif cell.revealed then 
    if cell.traps_around > 0 then
      return ''..cell.traps_around
    end
  end
    
  return false
end


function drawCell(i,j)

  local cell = grid[i][j]
  local canvas = getCellRectangle(i,j)
  
  local bgColor = getCellBackgroundColor(cell)
  local fgColor = getCellForegroundColor(cell) 
  local content = getCellDisplayContent(cell)

  renderCell( canvas, bgColor, fgColor, content )

end

function redrawField()
  for i = 1, config.cols do
    for j = 1, config.rows do
      drawCell(i,j)
    end
  end
end

function redraw()
  redrawField()
  redrawStatus()
end

function actionInit()
  flowInit()
  redraw()
end

initUI()
actionInit() 
