-- Simple Rectangle class for representing rectangle coordinates
Rectangle = {}
Rectangle.__index = Rectangle

-- Constructor: create a new Rectangle instance
function Rectangle:new(x, y, width, height)
    -- If called on an instance, add parent's coordinates
    if self ~= Rectangle then
        x = self.x + x
        y = self.y + y
    end
    -- Create new instance
    local instance = setmetatable({}, Rectangle)
    instance:init( x, y, width, height )
    return instance
end

function Rectangle:init(x, y, width, height)
  -- Store attributes
  self.x = x
  self.y = y
  self.w = width
  self.h = height
  self.x_end = self.x + self.w
  self.y_end = self.y + self.h
  self.x_mid = self.x + self.w / 2
  self.y_mid = self.y + self.h / 2
  self:setup_aliases()
end

function Rectangle:setup_aliases()
  self.width = self.w
  self.height = self.h
  self.top =  self.y
  self.bottom = self.y_end
  self.left = self.x
  self.right = self.x_end
end

function Rectangle:upper(new_height)
  if new_height<1 then
    new_height = self.height * new_height
  end
  return Rectangle:new( self.x, self.y, self.w, new_height )
end

function Rectangle:lower(new_height)
  if new_height < 1 then
    new_height = self.height * new_height
  end
  local new_y = self.y + (self.height - new_height)
  return Rectangle:new(self.x, new_y, self.w, new_height)
end

function Rectangle:central(w, h)

  local cx = self.x_mid - w/2
  local cy = self.y_mid - h/2
  return Rectangle:new( cx, cy, w, h )

end

function Rectangle:x_y_w_h()
  return self.x, self.y, self.w, self.h
end 

function Rectangle:inspect()
  local s = self
  local f = string.format
  local shape = f("%s x %s", self.w, self.h)
  local topleft = f("(%s,%s)", self.x, self.y)
  local bottomright = f("(%s,%s)", self.x_end, self.y_end)
  local center = f("(%s,%s)", self.x_mid, self.y_mid)
  local coords = topleft..".."..bottomright
  local result = shape.." ["..coords.."] -> "..center
  return result
end

return Rectangle
