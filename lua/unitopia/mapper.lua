-- Creates a map of arbitrary x, y and z coordinates,
-- room short descriptions and exits.
local class = require("pl.class")

class.Mapper()

function Mapper:_init()
  -- LastDirection is used to calculate the new coordinates
  self.LastDirection = nil
  -- Modes (0 = off, 1 = read, 2 = write)
  self.Mode = 0
  -- Coordinates
  self.X = 1000000
  self.Y = 1000000
  self.Z = 1000000
  -- Create database
  self.Database = sqlite3.open("mapper.sqlite")
  if self.Database == nil then
    world.Note("Mapper: Error opening database")
    return
  end
  self.Database:exec([[
    CREATE TABLE IF NOT EXISTS map(
      domain TEXT,
      x INTEGER,
      y INTEGER,
      z INTEGER,
      name TEXT,
      exits TEXT,
      PRIMARY KEY (domain, x, y, z)
    )
  ]])
  self.Insert = self.Database:prepare([[
    INSERT OR IGNORE INTO map(domain, x, y, z, name, exits)
    VALUES (@domain, @x, @y, @z, @name, @exits)
  ]])
  if self.Insert == nil then
    world.Note("Mapper: Error preparing insert statement")
    return
  end
  -- Add alias
  check(world.AddAlias("Mapper_Do", "map *", 'Mapper:Do("%1")', alias_flag.Enabled))
  check(world.SetAliasOption("Mapper_Do","send_to",12))
  world.Note("Mapper:_init done")
end

function Mapper:ChangeRoom(roomInfo)
  if self.Mode == 0 then
    return
  end
  if self.LastDirection == nil then
    world.Note("Mapper: Last direction is unknown")
    return
  end
  if self.LastDirection:find("w", 1, true) then
    self.X = self.X - 1
  elseif self.LastDirection:find("o", 1, true) then
    self.X = self.X + 1
  end
  if self.LastDirection:find("s", 1, true) then
    self.Y = self.Y - 1
  elseif self.LastDirection:find("n", 1, true) then
    self.Y = self.Y + 1
  end
  if self.LastDirection:find("h", 1, true) then
    self.Z = self.Z + 1
  elseif self.LastDirection:find("r", 1, true) then
    self.Z = self.Z - 1
  end
  if self.Mode == 2 then
    local exits = ""
    for key, value in pairs(roomInfo.exits) do
      exits = exits .. key .. "=" .. value .. ","
    end
    if self.Insert:bind(1, roomInfo.domain) ~= sqlite3.OK
      or self.Insert:bind(2, self.X) ~= sqlite3.OK
      or self.Insert:bind(3, self.Y) ~= sqlite3.OK
      or self.Insert:bind(4, self.Z) ~= sqlite3.OK
      or self.Insert:bind(5, roomInfo.name) ~= sqlite3.OK
      or self.Insert:bind(6, exits) ~= sqlite3.OK then
      world.Note("Mapper: Error binding parameters")
      return
    end
    if self.Insert:step() ~= sqlite3.DONE then
      world.Note("Mapper: Error inserting room")
      return
    end
    self.Insert:reset()
  end
  self.LastDirection = nil
end

function Mapper:Do(command)
  if command == "read" then
    self.LastDirection = nil
    self.Mode = 1
    world.Note("Mapper: Read mode")
  elseif command == "write" then
    self.LastDirection = nil
    self.Mode = 2
    world.Note("Mapper: Write mode")
  elseif command == "off" then
    self.Mode = 0
    world.Note("Mapper: Off")
  elseif command == "setpos" then
    Mapper:SetPosition()
  else
    world.Note("Mapper: Unknown command '" .. command .. "'")
  end
end

function Mapper:SetPosition()
  local input, newX, newY, newZ
  input = utils.inputbox("X:", "Mapper", self.X)
  if input == nil then
    return
  end
  newX = tonumber(input)
  if newX == nil or math.floor(newX) ~= newX then
    world.Note("Mapper: Invalid input: "..input)
    return
  end
  input = utils.inputbox("Y:", "Mapper", self.Y)
  if input == nil then
    return
  end
  newY = tonumber(input)
  if newY == nil or math.floor(newY) ~= newY then
    world.Note("Mapper: Invalid input: "..input)
    return
  end
  input = utils.inputbox("Z:", "Mapper", self.Z)
  if input == nil then
    return
  end
  newZ = tonumber(input)
  if newZ == nil or math.floor(newZ) ~= newZ then
    world.Note("Mapper: Invalid input: "..input)
    return
  end
  self.X = newX
  self.Y = newY
  self.Z = newZ
  world.Note("Mapper: position set")
end

return Mapper