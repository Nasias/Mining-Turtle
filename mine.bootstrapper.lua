local args = {...}

local INSTALL_REPO_URL = "https://raw.githubusercontent.com/Nasias/Mining-Turtle/refs/heads/main/"
local INSTALL_FILE_MANIFEST_URL = INSTALL_REPO_URL + "install_manifest"
local DEFAULT_INSTALL_PATH = "/mine/"

local function fetchInstallManifest(installManifestUrl)
   print("Downloading install manifest from: " .. installManifestUrl)

   local response, error, failedResponse = http.get(installManifestUrl)
   if not response then
      error("Failed to fetch install manifest: " .. (error or "Unknown error"))
   end

   local manifestContent = response.readAll()
   response.close()
   
   return manifestContent:replace("\r", ""):split("\n\r")
end

local function downloadFileAsync(remoteFileUrlToDownload, localFilePathToSaveTo)
   print("Downloading " .. remoteFileUrlToDownload)

   http.request(remoteFileUrlToDownload)

   while true do
      local eventType, eventUrl, eventHttpHandle = os.pullEvent();
      if eventType == "http_success" and eventUrl == remoteFileUrlToDownload then
         print(string.format("Saving %s to %s\n ", remoteFileUrlToDownload, localFilePathToSaveTo))
         local fileHandle = fs.open(localFilePathToSaveTo, "w+")
         fileHandle.write(eventHttpHandle.readAll())
         fileHandle.close()
         eventHttpHandle.close()
         print(string.format("Saved %s to %s\n ", remoteFileUrlToDownload, localFilePathToSaveTo))
         return true
      elseif eventType == "http_failure" and eventUrl == remoteFileUrlToDownload then
         print(string.format("Failed to fetch file %s", remoteFileUrlToDownload))
         return false
      end
   end
end

local function installFiles(installPath, installRepoUrl, installFileManifestUrl)
   local files = fetchInstallManifest(installFileManifestUrl)
   local tasks = {}
   local errorCount = 0

   for _, fileName in ipairs(files) do
      local requestUrl = installRepoUrl .. fileName
      tasks[#tasks + 1] = function()
         if not downloadFileAsync(requestUrl, installPath .. fileName) then
            errorCount = errorCount + 1
         end
      end
   end

   parallel.waitForAll(table.unpack(tasks))

   if errorCount > 0 then
      error(string.format("Failed to download %d files", errorCount))
   else
      print("All files downloaded")
   end
end

local installPath
if not args or #args == 0 then
   installPath = DEFAULT_INSTALL_PATH
elseif args[1] == "--install-path" and args[2] ~= nil then
   installPath = args[2]
end

print("--- mine.boostrapper ---\n")
installFiles(installPath, INSTALL_REPO_URL, INSTALL_FILE_MANIFEST_URL)