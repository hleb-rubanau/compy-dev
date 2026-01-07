-- Simple Rectangle class for representing rectangle coordinates
Rectangle = {}
Rectangle.__index = Rectangle

-- Constructor: create a new Rectangle instance
-- @param start_x, start_y: top-left corner coordinates (default 0, 0)
-- @param width, height: dimensions of the canvas
function Rectangle:new(start_x, start_y, width, height)
    -- Handle omitted start coordinates
    if height == nil then
        -- Called with 2 args: new(width, height)
        height = start_y
        width = start_x
        start_x = 0
        start_y = 0
    end
    
    -- If called on an instance (for sub-canvas), add parent's start coordinates
    if self ~= Rectangle then
        start_x = self.start_x + start_x
        start_y = self.start_y + start_y
    end
    
    -- Create new instance
    local instance = setmetatable({}, Rectangle)
    
    -- Store attributes
    instance.start_x = start_x
    instance.start_y = start_y
    instance.width = width
    instance.height = height
    instance.end_x = start_x + width
    instance.end_y = start_y + height
    instance.mid_x = start_x + width / 2
    instance.mid_y = start_y + height / 2

    -- syntactic sugar

    instance.sx = start_x
    instance.sy = start_y
    instance.ex = instance.end_x
    instance.ey = instance.end_y
    instance.mx = instance.mid_x
    instance.my = instance.mid_y
    instance.w  = instance.width
    instance.h  = instance.height
    instance.x  = instance.sx
    instance.y  = instance.sy
    instance.top =  instance.start_y
    instance.bottom = instance.end_y
    instance.left = instance.start_x
    instance.right = instance.end_x
    return instance
end


function Rectangle:upper(new_height)
  if new_height<1 then
    new_height = self.height * new_height
  end

  return Rectangle:new( self.sx, self.sy, self.w, new_height )
end

function Rectangle:lower(new_height)
  if new_height<1 then
    new_height = self.height * new_height
  end

  new_start_y = self.start_y + (self.height - new_height)

  return Rectangle:new( self.sx, new_start_y, self.w, new_height)
end

function Rectangle:central(w, h)

  local cx = self.mid_x - w/2
  local cy = self.mid_y - h/2
  return Rectangle:new( cx, cy, w, h )

end

function Rectangle:coordinates()
  return self.start_x, self.start_y, self.end_x, self.end_y 
end 

function Rectangle:x_y_w_h()
  return self.x, self.y, self.w, self.h
end 

function Rectangle:inspect()
  local s = self
  return string.format("%s x %s [ (%s,%s) .. (%s,%s) ] ; center -> (%s,%s)", s.w, s.h, s.sx, s.sy, s.ex, s.ey, s.mx, s.my)
  --return string.format("%s x %s [ (%s,%s) .. (%s,%s) ] ", self.w, self.h, self:coordinates() )
end

return Rectangle
