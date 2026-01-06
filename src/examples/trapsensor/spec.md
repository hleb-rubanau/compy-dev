# Design choices

## Gameplay

* First-safe-click rule (traps placement happens after 1st click, which is guaranteed to land on non-trap cell with no adjacent traps)
* Flood fill is optional (postponed until phase 1)
* Chording not provided for simplicity
* Stats tracking and displayign (time elapsed, clicks done, cells revealed) is not strictly necessary, but could greatly improve UX

## Implementation

* MVC-like separation of concerns
  * Model -- mutable 2D array (grid of cells) plus a bundle of runtime variables describing game status
  * View -- single method to redraw game grid from model state
  * Controller -- set of functions altering model and triggering redraws (clicks handler, mines placement, flood fill)
* Sequential traps placement with adjustable probabilities
* UI: decorations/visuals would be intentionally simplistic, not trying to resemble proprietary look. Prettiness is subject to best effort approach. :)

# Specifications

## Data (schemas and definitions)

### Configuration (hardcoded)

* Grid size (W,H)
* Traps number (T)
* Max depth of flood fill (Dmax)

### Core Model

Grid: 2-d array of (W,H) shape, consisting of cells

Cell: table of attributes
* `revealed`: bool
* `flagged`: bool
* `trap`: bool
* `blown`: bool
* `adjacent_traps`: int # 0..8

### Supporting runtime variables

* Game status: ('init','started','lost','won')
* Actual traps number (_in most cases is equal to config value, but must be reduced if setting happens to be extremely close to WxH_)
* Stats:
  * game start time
  * time elapsed
  * clicks counter
  * cells revealed

## View

* Main canvas: grid
* Sidebar or bottom bar: stats, hints, game status ('ready/lost/win'), optional restart button
* Full redraw (_partial redraws can be supported, but they actually would complicate the code_)

## Controllers/flows

In the specifications below, following conventions are used:

* 'Events' are events after recognition
* 'Actions' are functions triggered in response to user action
* 'Flows' are functions initiated from the code according to game logic
* Ternary operators and lowercase names are used occasionally for readability; the real code will follow coding style conventions


### UI events dispatching logic


```
start:                    action_init()
click on grid:            action_flag(x,y) 
doubleclick on grid:      game_not_finished ? action_reveal(x,y) : action_init()
click on restart button:  action_init()
```

Coordinates (x,y) are logical (in WxH space). Event dispatcher function ensures conversion between physical and logical coords.


### Action functions

Lists below describe high-level logic of action handlers. Subentries are steps within a function.

* `action_init`: 
  * invokes `flow_init`
  * redraw()

* `action_flag`:
  * if game not in progress: return
  * if cell is already revealed: return
  * toggles 'flagged' flag on target cell
  * redraw()

* `action_reveal`:
  * if game is finished: return
  * if cell is already revealed: return
  * if cell is flagged: return
  * if game not started (no cells revealed): invoke `flow_start` 
  * update stats: elapsed time, click counter
  * invoke `flow_reveal( x, y, depth=0 )` 
  * invoke `flow_evaluate_result(x,y)`
  * redraw()

### Flows

* `flow_init`
  * resets to initial values all runtime variables and core model (new grid with cell attributes set to false or 0)

* `flow_start(x:int,y:int)`:
  * resets game starting time
  * invokes `flow_placement(x,y)`

* `flow_placement(x:int, y:int)`:
    * calculates initial values of M (remaining mines to place) and N (remaining cell candidates):
      * N is grid area minus first-click zone size (first-click zone is protected from placement)
      * M is minimum of ( T, N ) -- in most cases it will be T (config value) unless it is explicitly set too high
    * for each cell:
      * skip if is adjacent to (x,y) -- first click zone protection
      * calculate placement probability (P=M/N)
      * decrement N
      * if random(0..1) <= P: 
        * decrement M
        * cell.trap = true
        * for every neighbour cell: increment 'adjacent_traps' attribute

* `flow_reveal(x:int, y:int, depth: int)`:

  * return if cell.revealed 
  * if cell.trap : cell.blown=true and return
  * update model: cell.revealed=true, counters.revealed++
  * optional flood-fill:
    * if cell.adjacent == 0 && (depth <= Dmax) :
      * for each neighbour as (xn,yn): 
        * if cell at (xn,yn) not revealed:
          * flow_reveal(xn,yn,depth=depth+1)
      * redraw() # purely for cascaded visualization of flood-fill; skip if no recursions were triggered

* `flow_evaluate_result(x,y)`:
  * if cell at (x,y) is blown trap: game status = 'loss' 
  * if all non-mines revealed: game status='win'


