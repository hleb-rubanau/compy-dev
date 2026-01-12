-- Title: Trap Sensor
gfx = love.graphics
Rectangle = require("rectangle")

--- constants 

TRAPS_PERCENT=15
FLOODFILL=false
DEFAULT_MODE = { 9, 9, 12 }

CELL_SIZE=32
CELL_FONTSIZE = 28

STATUS_PANEL_SIZE = 0.1
STATUS_PANEL_FONTSIZE = 24
STATUS_PANEL_PADDING  = STATUS_PANEL_FONTSIZE / 2
STATUS_PANEL_ALIGN = 'center'

colors = {
  main_panel_bg = Color[Color.blue],
  field_border = Color[Color.white],
  status_panel_bg = Color[Color.bright],
  status_panel_border = Color[Color.green],
  status_panel_text = Color[Color.yellow],
  hints_text = Color[Color.green],
  cell_bg_not_revealed = { 0.5, 0.5, 0.5 },
  cell_bg_revealed = Color[Color.green],
  cell_bg_flagged = Color[Color.yellow],
  cell_bg_blown = Color[Color.red],
  cell_fg_trap = Color[Color.black],
  cell_fg_flagged = Color[Color.red],
  cell_fg_default = Color[Color.blue],
  cell_fg_revealed_1 = Color[Color.white],
  cell_fg_revealed_2 = Color[Color.black],
  cell_fg_revealed_3 = Color[Color.magenta],
  cell_fg_revealed_4 = Color[Color.red]
}

fonts = {
  status = gfx.newFont(STATUS_PANEL_FONTSIZE),
  cell   = gfx.newFont(CELL_FONTSIZE)
} 

-- runtime variables, to be initialized

mode_idx = 1
modes = { }
rectangles = { }
config = { }
state = { }
grid = { }
counters = { }
traps = { }

function logdebug(...)
  if love.DEBUG then
    local msg = string.format(...)
    print(msg)
  end
end

-- layouts(rectangles) -- immutable areas on screen

function initLayoutStatusPanel()
  local th = font.getHeight(fonts.status)
  local vpad = th*0.5
  local panel_height = vpad + th + vpad + th + vpad

  local sp = rectangles.screen:lower(panel_height)
  
  local status_box = sp:new(0, vpad, sp.w, th)
  local hints_box  = sp:new(0, (vpad+th+vpad), sp.w, th )

  rectangles.status_panel = sp
  rectangles.status_box = status_box
  rectangles.hints_box = hints_box
end

function initLayoutMainPanel()
  local screen = rectangles.screen
  local sp = rectangles.status_panel
  rectangles.main_panel = screen:upper( screen.h - sp.h)
end

function initLayoutUI()
  local screen_w, screen_h = gfx.getDimensions()
  rectangles.screen = Rectangle:new(0, 0, screen_w, screen_h)

  initLayoutStatusPanel()
  initLayoutMainPanel()
end 

-- modes ( cols,rows,traps ) -- derived from panel layout

function initModes()
  local main_panel = rectangles.main_panel
  local max_cols = math.floor( main_panel.width / CELL_SIZE )
  local max_rows = math.floor( main_panel.height / CELL_SIZE )
  local max_cells = max_cols * max_rows
  local max_traps = math.ceil( max_cells * TRAPS_PERCENT / 100 )
  local mid_cols = math.floor( max_cols / 10 )*10
  local mid_rows = math.floor( max_rows / 10 )*10
  local mid_cells = mid_cols * mid_rows 
  local mid_traps = math.ceil( mid_cells * TRAPS_PERCENT / 100 )
  modes[1] = DEFAULT_MODE
  modes[2] = { mid_cols, mid_rows, mid_traps }
  modes[3] = { max_cols, max_rows, max_traps }
end

-- gamefield layout is dynamic, it depends on configured mode

function setLayoutGameField()
  local width = config.cell_size * config.cols
  local height = config.cell_size * config.rows

  local mp = rectangles.main_panel
  rectangles.field = mp:central( width, height )
end

--- visualisation 

--- visualisation: main panels

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
  gfx.setColor(colors.main_panel_bg)
  gfx.rectangle("fill", rectangles.main_panel:x_y_w_h() )
end 

function drawStatusPanel(status_line, hints_line)
  gfx.setColor(colors.status_panel_bg)
  gfx.rectangle("fill", rectangles.status_panel:x_y_w_h() )
  gfx.setColor(colors.status_panel_border)
  gfx.rectangle("line", rectangles.status_panel:x_y_w_h() )
  gfx.setFont(fonts.status) 
  
  local sb = rectangles.status_box
  gfx.setColor(colors.status_panel_text)
  gfx.printf( status_line, sb.x, sb.y, sb.w, STATUS_PANEL_ALIGN)
  local hb = rectangles.hints_box
  gfx.setColor(colors.hints_text)
  gfx.printf( hints_line, hb.x, hb.y, hb.w, STATUS_PANEL_ALIGN)
end

--- visualisation: status panel and its helpers

function statusStatsLine()
  local c = counters
  local f = string.format
  local substrings = { 
    f("Flagged: %s/%s", c.flagged, c.traps),
    f("Opened: %s/%s", c.revealed, config.n_cells ),
    f("Clicks: %s (%s s)", c.clicks, c.seconds)
  }
  return table.concat(substrings, " | ")
end

function statusReadyLine() 
  local c = config.cols
  local r = config.rows
  local t = config.n_traps
  local f = string.format
  local msg = f("Ready! Field: %s x %s, traps: %s", c,r,t)
  return msg
end

function getStatusLine()
  if (state.status == 'ready') then
    return statusReadyLine()
  end 
  local msg = statusStatsLine()
  if (state.status=='finished') then
    local prefix = string.upper(state.result)
    msg = '['..prefix..'] '..msg
  end
  return msg
end 

function getHintsLine()
  local msg = ''
  if (state.status == 'finished') then
    msg = "Double-click or press [r] for restart"
  end
  if (state.status == 'ready') then
    msg = "Click to change mode, double-click to start"
  end
  if (state.status == 'started') then
    msg = "Click to flag, double-click to open, [r] to restart"
  end
  return msg
end

function drawStatus()
  local status_line  = getStatusLine()
  local hints_line = getHintsLine()
  drawStatusPanel( status_line, hints_line )
end 

--- visualisation: cells and gamefield

function getCellRectangle(i,j)
  local field = rectangles.field
  local c = config.cell_size
  local cell_x_rel = (i-1)*c
  local cell_y_rel = (j-1)*c
  return field:new( cell_x_rel, cell_y_rel, c, c)
end

function writeCellLabel(canvas, content, fgColor)
  gfx.setColor( fgColor )
  gfx.setFont( fonts.cell )
  local fontHeight = fonts.cell:getHeight()
  local text_y = canvas.y_mid - (fontHeight/ 2 )
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
    return colors.cell_bg_flagged
  elseif cell.blown then
    return colors.cell_bg_blown
  elseif cell.revealed then
    return colors.cell_bg_revealed
  else
    return colors.cell_bg_not_revealed
  end
end

function getTrapsAroundColor(n_traps_nearby)
  for v = 8,1,-1 do
    if n_traps_nearby >= v then
      local color_name = "cell_fg_revealed_"..v
      if colors[color_name] then
        return colors[color_name]
      end
    end
  end
  return colors.cell_fg_default
end

function getCellForegroundColor(cell)
  if cell.flagged then
    return colors.cell_fg_flagged
  elseif cell.trap then
    return colors.cell_fg_trap
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

--- visualisation: redraw hook (only field and status)

function redraw(i,j)
  redrawField()
  drawStatus()
end

--- data: grid and cells

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

--- flows (updating game state via runtime variables)

function flowInitConfig()
  local mode = modes[ mode_idx ]
  local cols, rows, traps = unpack(mode)

  config.cell_size = CELL_SIZE
  config.floodfill = FLOODFILL
  config.cols = cols
  config.rows = rows
  config.n_cells = cols * rows
  config.n_traps = traps
end

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

function flowInitState()
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
  
  --logdebug("Trap #%s at: (%s, %s)", counters.traps, i, j) 

  local neighbours = getNeighbourPositions(i,j)
  for idx, position in ipairs(neighbours) do
    local pos_i, pos_j = unpack(position)
    local neighbour = grid[ pos_i ][ pos_j ]
    neighbour.n_traps_nearby = neighbour.n_traps_nearby + 1
  end
end

-- [i,j] is the firt click index, guaranteed to be safe zone
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
  --logdebug("GAME STARTS...")
  flowTrapsPlacement(i,j)
  
  state.status = 'started'
  state.started = os.time()
  counters.clicks = 0
  counters.seconds = 0
  counters.revealed = 0
  counters.flagged = 0
  counters.blown = 0 
  counters.pending = config.n_cells - counters.traps
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
  logdebug("Revealing cell at (%s,%s)",i,j)
  local cell = grid[i][j]
  if cell.revealed or cell.trap then
    logdebug("-> Backoff: revealed=%s, trap=%s", cell.revealed, cell.trap)
    return 
  end 
  cell.revealed = true
  counters.revealed = counters.revealed + 1
  counters.pending = counters.pending - 1
  if cell.n_traps_nearby == 0 and config.floodfill then
    local neighbours = getNeighbourPositions(i,j)
    logdebug("FLOODFILL START at (%s,%s): %s neighbours", i, j, #neighbours)
    for _, pos in ipairs(neighbours) do
      flowRevealCell( pos[1], pos[2] )
      --redraw()
    end 
  end
end 

-- blow or reveal 
function flowCheckCell(i,j)
  local cell = grid[i][j]
  if cell.trap then
    cell.blown = true
    counters.blown = counters.blown + 1
  else
    -- lots of logic, factored into separate function
    flowRevealCell(i,j)
  end
end

function flowEvaluateGameStatus(i,j)
  if counters.pending == 0 then
    state.status = 'finished'
    state.result = 'win'
  end
 
  if counters.blown > 0 then
    state.status = 'finished'
    state.result = 'lost'
    for n, cell in ipairs(traps) do
      cell.exposed = true
    end
  end 
end 

function flowReveal(i,j)
  flowTrackClick() 
  flowCheckCell(i,j)
  flowEvaluateGameStatus(i,j)
end

--- actions (trigger flows in response to user activity)

function actionInit()
  flowInitConfig()
  flowInitState()
  setLayoutGameField()
end

function actionFlag(i,j) 
  local cell = grid[i][j]

  if not(cell.revealed) then
    cell.flagged = not(cell.flagged)

    local adjust = cell.flagged and 1 or -1
    counters.flagged = counters.flagged + adjust

    flowUpdateTimer() 
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
end

function actionNextMode()
  if mode_idx == #modes then
    mode_idx = 1
  else
    mode_idx = mode_idx + 1 
  end
  actionInit()
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
  local y_valid = ( y >= field.y ) and ( y <= field.y + field.h)
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

--- game actions dispatcher

actions = {
  flag = actionFlag,
  reveal = actionReveal
}

function dispatchAction(action_name, x, y)
  local action_allowed = isActionAllowed(action_name)
  local click_within_field = isPointInGameField(x, y)

  if action_allowed then
    flowUpdateTimer()
    if click_within_field then
      local i, j = detectCellPosition(x,y)
      logdebug("Action: %s -> [%s,%s]", action_name, i, j)
      local action = actions[action_name]
      action( i, j )
    end
  end
end

--- events binding

function love.singleclick(x,y)
  if state.status == 'started' then
    dispatchAction('flag', x, y )
  else
    if state.status == 'ready' then
      actionNextMode()
    end
  end
end

function love.doubleclick(x,y)
  if state.status=='finished' then
    actionInit()
  else
    dispatchAction('reveal', x, y )
  end
end

function love.keyreleased(k)
  if k == "r" then
    actionInit()
  end
end

function love.draw()
  redraw()
end

--- game initialization

initLayoutUI()
initModes()
actionInit()
