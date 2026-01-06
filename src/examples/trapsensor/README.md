# Trap Sensor

Trap Sensor is a grid-based puzzle game where players must reveal all safe cells while avoiding hidden traps. The game features configurable difficulty levels, a clean UI with status tracking, and classic Minesweeper mechanics.

## Project Architecture

### Key Design Decisions

- **Safe First Click**: Traps are placed *after* first reveal, excluding that cell and neighbors
- **Optional Flood Fill support**: Recursive reveal disabled/enabled via hardcoded setting
- **Stateless Rendering**: All visual state derived from data; no separate render state

### Core Concepts

#### 1. Layout System (`rectangles`)

Given that game has no *moving* parts, UI is built as hierarchy of rectangles

The `Rectangle` class (`rectangle.lua`) provides geometric abstraction for UI layout:

- **Coordinate Management**: Stores position (x, y) and dimensions (w, h) with computed properties for edges and center points
- **Relative Positioning**: Child rectangles inherit parent coordinates for hierarchical layouts
- **Layout Helpers**: Methods for positioning child rectangle (`upper`, `lower`, `central`)
- **Aliases**: Multiple ways to reference the same attributes (width/w, height/h, top/bottom/left/right)

AFter initialization each rectangle exposes absolute coordinates.

The layout hierarchy:
```
screen
│── main_panel (top)
    └── field (centered grid)
└── status_panel (bottom)
    ├── status_box (game stats)
    └── hints_box (user guidance)
```

#### 2. Configuration & Modes

Three difficulty presets adjust grid size and trap count:
- **Default**: 9×9 grid with 12 traps
- **Medium**: Dynamic sizing to 10-cell increments
- **Maximum**: Fills available screen space

Configuration is calculated from:
- Panel dimensions (derived from screen size)
- Cell size constants (32px)
- Selected mode

#### 3. Game State Management

**State Variables:**
- `state`: Game phase (ready/started/finished) and outcome (win/lost)
- `grid`: 2D array of cell objects with properties (revealed, flagged, trap, blown, n_traps_nearby)
- `counters`: Statistics tracking (clicks, seconds, revealed cells, flags, pending cells)
- `traps`: Reference array of all trap cells, used for final exposure

**State Transitions:**
- `ready` → `started`: First cell reveal (triggers trap placement)
- `started` → `finished`: All safe cells revealed (win) or trap hit (lost)

#### 4. Separation of concerns

* `flow` functions only alter model state
* `action` functions trigger flows and reinitialize gamefield as needed (gamefield is the only UI panel with mutable geometry)
* `redraw` function provides stateless rendering -- full layout is redrawn from the model state

#### 5. Key Algorithms
- **Trap Placement**: Random selection from non-neighboring positions: 
  - Ensures first click is always safe
  - Dynamically tweaks placement probability to guarantee placement of all traps
- **Neighbor Counting**: Each trap placement increments the `n_traps_nearby` counter for surrounding cells
- **Flood Fill**: Optional recursive reveal of connected zero-trap cells (currently disabled via `FLOODFILL=false`)

## User Actions

Actions are dispatched through a validation layer:

```
User Input → Event Handler (love.singleclick/doubleclick/keyreleased)
          → Dispatcher (checks status, validates position, converts physical coordinates to cell index)
          → Action Function (actionFlag/actionReveal/actionNextMode)
          → Flow Functions
```

**Interaction Model:**
- Single-click: Flag cell (during game) or cycle modes (before game)
- Double-click: Reveal cell or restart (when finished)
- 'R' key: Restart at any time
