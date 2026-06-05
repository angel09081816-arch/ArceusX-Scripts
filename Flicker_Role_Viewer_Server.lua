-- Optional server helper for the clean viewer.
-- Place this in ServerScriptService if you want a richer snapshot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function isRoleKeyword(name)
    local lower = string.lower(name or "")
    return string.find(lower, "role", 1, true)
        or string.find(lower, "rank", 1, true)
        or string.find(lower, "team", 1, true)
        or string.find(lower, "faction", 1, true)
        or string.find(lower, "title", 1, true)
        or string.find(lower, "group", 1, true)
        or string.find(lower, "perm", 1, true)
        or string.find(lower, "access", 1, true)
        or string.find(lower, "journal", 1, true)
        or string.find(lower, "diary", 1, true)
        or string.find(lower, "notes", 1, true)
end

local function normalizeText(value)
    if value == nil then
        return ""
    end

    local t = typeof(value)
    if t == "Instance" then
        if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("BoolValue") then
            return tostring(value.Value)
        end
        return value.Name
    end

    if t == "string" or t == "number" or t == "boolean" then
        return tostring(value)
    end

    return tostring(value)
end

local function addEntry(list, name, value)
    local text = normalizeText(value)
    if text ~= "" then
        table.insert(list, { name = name, value = text })
    end
end

local function collectSnapshot(player)
    local roles = {}
    local journals = {}

    for _, child in ipairs(player:GetChildren()) do
        if isRoleKeyword(child.Name) then
            if string.find(string.lower(child.Name), "journal", 1, true) or string.find(string.lower(child.Name), "diary", 1, true) or string.find(string.lower(child.Name), "notes", 1, true) then
                addEntry(journals, child.Name, child)
            else
                addEntry(roles, child.Name, child)
            end
        end
    end

    for _, desc in ipairs(player:GetDescendants()) do
        if isRoleKeyword(desc.Name) then
            if string.find(string.lower(desc.Name), "journal", 1, true) or string.find(string.lower(desc.Name), "diary", 1, true) or string.find(string.lower(desc.Name), "notes", 1, true) then
                addEntry(journals, desc.Name, desc)
            else
                addEntry(roles, desc.Name, desc)
            end
        end
    end

    for key, value in pairs(player:GetAttributes()) do
        if isRoleKeyword(key) then
            addEntry(roles, "Attribute:" .. key, value)
        end
    end

    if player.Team then
        addEntry(roles, "Team", player.Team.Name)
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if isRoleKeyword(stat.Name) then
                local lower = string.lower(stat.Name)
                if string.find(lower, "journal", 1, true) or string.find(lower, "diary", 1, true) or string.find(lower, "notes", 1, true) then
                    addEntry(journals, stat.Name, stat.Value)
                else
                    addEntry(roles, stat.Name, stat.Value)
                end
            end
        end
    end

    return { roles = roles, journals = journals }
end

local existing = ReplicatedStorage:FindFirstChild("FlickerRoleViewerRemote")
if existing then
    existing:Destroy()
end

local remote = Instance.new("RemoteFunction")
remote.Name = "FlickerRoleViewerRemote"
remote.Parent = ReplicatedStorage

remote.OnServerInvoke = function(player, action)
    if action ~= "GetRoleData" then
        return nil
    end

    local snapshot = { players = {} }
    for _, other in ipairs(Players:GetPlayers()) do
        snapshot.players[tostring(other.UserId)] = collectSnapshot(other)
    end
    return snapshot
end
