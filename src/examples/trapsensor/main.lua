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
  --status = gfx.newFont(32),
  status = gfx.newFont(24),
  cell   = gfx.newFont(28)
} 

-- to be initialized
rectangles = { }
state = { }
config = { }
grid = { }
counters = { }
traps = { }

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

  config.cell_size = CELL_SIZE
  config.cols = math.floor( mp.width / config.cell_size )
  config.rows = math.floor( mp.height / config.cell_size )
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
  --local padding = ( sp.height - textbox_height ) / 2
  local padding = 5
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

function statusStatsLine()
  local named_stats = {
    Traps = counters.traps,
    Clicks = counters.clicks, 
    Open = counters.revealed,
    Left = counters.pending,
    Time = counters.seconds
  } 
  local substrings = { }
  for k,v in pairs(named_stats) do
    substrings[#substrings+1] = k .. ": " ..v
  end
  return table.concat(substrings, " | ")
end

function statusReadyLine() 
  local details_tmpl = "field: %sx%s, traps: %s"
  local c = config.cols
  local r = config.rows
  local t = config.n_traps
  local details_txt = string.format(details_tmpl, c, r, t)

  local base_txt = "Ready! Double-click any cell to start..."
  local msg = base_txt .. ' ('..details_txt..')'
  return msg
end

function redrawStatus()
  local msg = ''
  if (state.status == 'ready') then
    msg = statusReadyLine()
  else
    msg = statusStatsLine()
    if (state.status=='finished') then
      local prefix = string.upper(state.status)
      msg = '['..prefix..'] '..msg
    end
  end
  drawStatus(msg)
end 

function getCellRectangle(i,j)
  local field = rectangles.field
  local c = config.cell_size
  local cell_x = field.x + (i-1)*c
  local cell_y = field.y + (j-1)*c
  return field:new( cell_x, cell_y, c, c)
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

function getTrapsAroundColor(n_traps_nearby)
  for v = 4,1 do
    if n_traps_nearby >= v then
      return colors["cell_revealed_fg_"..v]
    end
  end
  return colors.cell_default_fg
end

function getCellForegroundColor(cell)
  if cell.flagged then
    return colors.cell_flagged_fg
  elseif cell.trap then
    return colors.cell_trap_fg
  else
    return getTrapsAroundColor(cell.n_traps_nearby)
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
    if cell.n_traps_nearby > 0 then
      return ''..cell.n_traps_nearby
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

--- data structures and functions

function newCell() 
  local cell = {
    revealed = false,
    flagged = false,
    trap = nil,
    exposed = false,
    blown = false,
    n_traps_nearby = 0,
  }
  return cell
end

function getNeighbourPositions(i, j)
  local result = { }
  local i_min = math.max(i-1, 1)
  local i_max = math.min(i+1, config.cols)
  local j_min = math.max(j-1, 1)
  local j_max = math.min(j+1, config.rows)
  for n = i_min, i_max do
    for m = j_min, j_max do
      local is_original = (n==i) and (m==j)
      if not is_original then
        table.insert(result, {n,m})
      end
    end
  end
  return result 
end

function getNonNeighbourPositions(i, j)
  local result = { }
  for n = 1, config.cols do
    local i_near = math.abs( i - n ) <= 1
    for m = 1, config.rows do
      local j_near = math.abs( j - m ) <= 1
      local proximity = i_near and j_near
      if not proximity then
        table.insert(result, {n,m})
      end      
    end
  end
  return result
end


--- flows
--- modify game state

function flowInitGrid() 
  grid = { }
  for i = 1, config.cols do
    local col = {}
    for j = 1, config.rows do
      col[j] = newCell()
    end
    grid[i] = col
  end
end

function flowInit()
  state.status = 'ready'
  state.result = nil
  state.started = nil

  counters.revealed = 0
  counters.seconds =  0
  counters.clicks = 0
  counters.pending = 0
  counters.traps = 0
  
  flowInitGrid()
end

function flowPlaceTrap(i,j) 
  local cell = grid[i][j]
  cell.trap = true
 
  table.insert( traps, cell ) -- for later reference
  counters.traps = counters.traps+1
  
  logdebug("Trap #%s at: (%s, %s)", counters.traps, i, j) 

  local neighbours = getNeighbourPositions(i,j)
  for idx, position in ipairs(neighbours) do
    local pos_i, pos_j = unpack(position)
    local neighbour = grid[ pos_i ][ pos_j ]
    neighbour.n_traps_nearby = neighbour.n_traps_nearby + 1
  end
end

function flowTrapsPlacement(i,j)
  math.randomseed(os.time())
  local positions = getNonNeighbourPositions( i, j )
  local n = #positions
  local m = math.min( config.n_traps, n )
  for ipos, pos in ipairs(positions) do
    local p = (m / n)
    local selected = math.random() < p
    if selected then
      flowPlaceTrap( unpack(pos) )
      m = m - 1
    end
    n = n - 1
  end 
end

function flowStart(i,j) 

  flowTrapsPlacement(i,j)
  
  state.status = 'started'
  state.started = os.time()
  counters.seconds = 0
  counters.blown = 0 
  counters.revealed = 0
end

function flowUpdateTimer()
  if state.started then
    counters.seconds = os.time() - state.started
  end
end

function flowTrackClick() 
  counters.clicks = counters.clicks + 1
end

function flowRevealCell(i,j)
  local cell = grid[i][j]
  if cell.revealed then
    return 
  end 
  cell.revealed = true
  counters.revealed = counters.revealed + 1
  counters.pending = counters.pending - 1
  if cell.n_traps_nearby == 0 then
    local positions = getNeighbourPositions(i,j)
    for _, pos in ipairs(positions) do
      flowRevealCell( pos[1], pos[2] )
      redraw()
    end 
  end
end 

function flowCheckCell(i,j)
  local cell = grid[i][j]
  if cell.trap then
    cell.blown = true
    counters.blown = counters.blown + 1
  else
    flowRevealCell(i,j)
  end
end

function flowEvaluateGameStatus(i,j)
  if counters.pending == 0 then
    state.status = 'win'
  end
 
  if counters.blown > 0 then
    state.status = 'lost'
    for n, cell in ipairs(traps) do
      cell.exposed = true
    end
  end 
end 

function flowReveal(i,j)
  
  flowTrackClick() 
  
  flowRevealCell(i,j)
  flowEvaluateGameStatus(i,j)

  redraw() 
end

--- actions 
--- (check conditions, initiate flows and redraws)

function actionInit()
  flowInit()
  redraw()
end

function actionFlag(i,j) 
  local cell = grid[i][j]
  if not(cell.revealed) then
    cell.flagged = not(cell.flagged)
    flowUpdateTimer() 
    redraw()
  end
end

function actionReveal(i,j)
  local game_not_started = (state.status == 'ready')
  if game_not_started then
    flowStart(i,j)
  end
  
  local cell = grid[i][j]
  local can_be_revealed = not( cell.revealed or cell.flagged )
  if can_be_revealed then
    flowReveal(i,j) 
  end
  flowUpdateTimer() 
  redraw()
end

--- events dispatching helpers 


function isActionAllowed(action_name)
  local game_status = state.status
  if game_status == 'started' then
    return true
  end
  -- first reveal starts the game
  if game_status == 'ready' then
    if action_name == 'reveal' then
      return true
    end
  end
  return false
end 

function isPointInGameField(x,y)
  local field = rectangles.field
  local x_valid = ( x >= field.x ) and ( x <= field.x + field.w)
  local y_valid = ( x >= field.y ) and ( y <= field.y + field.h)
  return x_valid and y_valid
end

function detectCellPosition(x,y)
  local field = rectangles.field 
  local x_rel = x - field.x
  local y_rel = y - field.y
  local c = config.cell_size
  local i = math.ceil( x_rel / c )
  local j = math.ceil( y_rel / c )
  -- corner cases, left boundary still is cell 
  if x_rel == 0 then
    i = 1
  end
  if y_rel == 0 then
    j = 1 
  end
  return i,j
end

--- interaction events dispatcher

actions = {
  flag = actionFlag,
  reveal = actionReveal
}

function dispatchAction(action_name, x, y)
  local action_allowed = isActionAllowed(action_name)
  local click_within_field = isPointInGameField(x, y)

  logdebug("Action name: "..action_name)
  logdebug("Action allowed:"..action_allowed)
  logdebug("Click in field: "..click_within_field)

  if action_allowed then
    flowUpdateTimer()
    if click_within_field then
      local i, j = detectCellPosition(x,y)

      local action = actions[action_name]
      action( i, j )
    end
  end
end

--- interaction events handling

function love.singleclick(x,y)
  dispatchAction('flag', x, y )
end

function love.doubleclick(x,y)
  dispatchAction('reveal', x, y )
end

function love.keyreleased(k)
  if k == "r" then
    actionInit()
  end
end

--- start 

initUI()
actionInit()
