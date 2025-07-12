local mainFileUrl = "https://raw.githubusercontent.com/Nasias/Mining-Turtle/refs/heads/main/mine.lua"

print("Downloading main file from: " .. mainFileUrl)
local response, error, failedResponse  = http.get(mainFileUrl)
if not response then
   error("Failed to fetch main file: " .. (error or "Unknown error"))
end

print("Saving " .. mainFileUrl)
local fileHandle = fs.open("mine.lua", "w+")
fileHandle.write(response.readAll())
fileHandle.close()
response.close()

shell.run("mine.lua", "--install")