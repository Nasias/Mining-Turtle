local args = {...}

local function downloadFiles()
   local repoUrl = "https://raw.githubusercontent.com/Nasias/Mining-Turtle/refs/heads/main/"
   local files = { "mine.lua", "lib/inifile.lua" }
   local downloadRequests = {}
   for _, fileName in ipairs(files) do
      local requestUrl = repoUrl .. fileName
      http.request(requestUrl)
      downloadRequests[requestUrl] = fileName
      print("Downloading " .. requestUrl)
   end

   while true do
      local event, requestUrl, httpHandle = os.pullEvent();
      if event == "http_success" and downloadRequests[requestUrl] then
         print("Saving " .. requestUrl)
         local fileHandle = fs.open(downloadRequests[requestUrl], "w")
         fileHandle.write(httpHandle.readAll())
         fileHandle.close()
         httpHandle.close()

         downloadRequests[requestUrl] = nil
         print("Saved " .. requestUrl)
         if next(downloadRequests) == nil then
            return
         end
      elseif event == "http_failure" then
         error("Failed to fetch " .. requestUrl, 0)
      end
   end
end

local function install()
   downloadFiles()
   print("Files downloaded successfully.")
end

if not args or #args == 0 then
   print("mine.lua | Program mode (one is required):")
   print("  [--install] | Install latest version")
   print("  [--start]   | Start the program")
elseif args[1] == "--install" then
   install()
elseif args[1] == "--start" then
   print("Not yet implemented")
else
   print("mine.lua | Program mode (one is required):")
   print("  [--install] | Install latest version")
   print("  [--start]   | Start the program")
end

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