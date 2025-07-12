local args = {...}

local inifile = require "lib.inifile"
local pathfinding = require "lib.pathfinding"

local config = inifile.parse("/mine/config.ini")

print("Starting mining program with the following configuration:")
for section, keys in pairs(config) do
   print(string.format("[%s]", section))
   for key, value in pairs(keys) do
      if type(value) == "table" and value.x ~= nil and value.y ~= nil and value.z ~= nil then
         print(string.format("%s=%d|%d|%d)", value.x, value.y, value.z))
      else
         print(string.format("%s=%s", key, value))
      end
   end
end

pathfinding.init(config.miningPlan.size)

parallel.waitForAll(function ()
   local moveWasValid = pathfinding:executeNextMove();
   while moveWasValid do
      coroutine.yield()
      moveWasValid = pathfinding:executeNextMove();
   end
end)