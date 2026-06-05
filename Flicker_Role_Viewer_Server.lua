-- Flicker Role Viewer server helper
-- Place this in ServerScriptService.
-- It exposes a safe snapshot of role / journal-like values to the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function normalizeValue(value)
    if value == nil then
        return ""
    end

    local valueType = typeof(value)
    if valueType == "Instance" then
        if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("BoolValue") then
            return tostring(value.Value)
        end
        if value:IsA("Folder") or value:IsA("Model") then
            return value.Name
        end
        return value.Name
    end

    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end

    return tostring(value)
end

local function isRoleLikeName(name)
    local lower = string.lower(name or "")
    return string.find(lower, "role")
        or string.find(lower, "rank")
        or string.find(lower, "team")
        or string.find(lower, "faction")
        or string.find(lower, "title")
        or string.find(lower, "perm")
        or string.find(lower, "access")
        or string.find(lower, "group")
        or string.find(lower, "journal")
        or string.find(lower, "diary")
        or string.find(lower, "notes")
end

local function classifyName(name)
    local lower = string.lower(name or "")
    if string.find(lower, "journal") or string.find(lower, "diary") or string.find(lower, "notes") then
        return "journal"
    end
    return "role"
end

local function addEntry(list, category, name, value)
    if value == nil then
        return
    end

    local text = normalizeValue(value)
    if text ~= "" then
        table.insert(list, { name = name, value = text, category = category })
    end
end

local function collectServerEntries(player)
    local roles = {}
    local journals = {}

    for _, child in ipairs(player:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") or child:IsA("ValueBase") then
            if isRoleLikeName(child.Name) then
                if classifyName(child.Name) == "journal" then
                    addEntry(journals, "journal", child.Name, child)
                else
                    addEntry(roles, "role", child.Name, child)
                end
            end
        end
    end

    for _, descendant in ipairs(player:GetDescendants()) do
        if descendant:IsA("ValueBase") or descendant:IsA("Folder") or descendant:IsA("Model") then
            if isRoleLikeName(descendant.Name) then
                if classifyName(descendant.Name) == "journal" then
                    addEntry(journals, "journal", descendant.Name, descendant)
                else
                    addEntry(roles, "role", descendant.Name, descendant)
                end
            end
        end
    end

    for key, value in pairs(player:GetAttributes()) do
        if isRoleLikeName(key) then
            addEntry(roles, "role", "Attribute:" .. key, value)
        end
    end

    if player.Team then
        addEntry(roles, "role", "Team", player.Team.Name)
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if isRoleLikeName(stat.Name) then
                if classifyName(stat.Name) == "journal" then
                    addEntry(journals, "journal", stat.Name, stat.Value)
                else
                    addEntry(roles, "role", stat.Name, stat.Value)
                end
            end
        end
    end

    return {
        roles = roles,
        journals = journals,
    }
end

local function ensureRemoteFunction()
    local existing = ReplicatedStorage:FindFirstChild("FlickerRoleViewerRemote")
    if existing then
        existing:Destroy()
    end

    local remote = Instance.new("RemoteFunction")
    remote.Name = "FlickerRoleViewerRemote"
    remote.Parent = ReplicatedStorage
    return remote
end

local remote = ensureRemoteFunction()

remote.OnServerInvoke = function(player, action)
    if action ~= "GetRoleData" then
        return nil
    end

    local snapshot = { players = {} }
    for _, other in ipairs(Players:GetPlayers()) do
        snapshot.players[tostring(other.UserId)] = collectServerEntries(other)
    end

    return snapshot
end
