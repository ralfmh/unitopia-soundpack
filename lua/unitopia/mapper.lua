-- Creates a map of arbitrary x, y and z coordinates,
-- room short descriptions and exits.
local class = require("pl.class")

class.Mapper()

function Mapper:_init()
  -- LastDirection is used to calculate the new coordinates
  self.LastDirection = nil
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
  world.Note("Mapper:_init done")
end

function Mapper:InsertRoom(roomInfo)
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
  self.LastDirection = nil
end

return Mapper