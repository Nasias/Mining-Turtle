local args = {...}

-- local inifile = require("lib.inifile")
-- local config = inifile.parse("config.ini")
-- for section, keys in pairs(config) do
--    print(string.format("[%s]", section))
--    for key, value in pairs(keys) do
--       if type(value) == "table" and value.x ~= nil and value.y ~= nil and value.z ~= nil then
--          print(string.format("%s=%d|%d|%d)", value.x, value.y, value.z))
--       else
--          print(string.format("%s=%s", key, value))
--       end
--    end
-- end