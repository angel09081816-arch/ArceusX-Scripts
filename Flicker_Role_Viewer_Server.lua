-- Optional server helper for the fresh Flicker role viewer.
-- Place this into ServerScriptService if you want richer role snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function isRoleKeyword(name)
    local lower = string.lower(tostring(name or ""))
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

local function normalizeValue(value)
    if value == nil then
        return ""
    end

    local kind = typeof(value)
    if kind == "Instance" then
        if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("BoolValue") then
            return tostring(value.Value)
        end
        return tostring(value.Name)
    end

    return tostring(value)
end

local function addEntry(list, name, value)
    local text = normalizeValue(value)
    if text ~= "" then
        table.insert(list, { name = tostring(name), value = text })
    end
end

local function collectSnapshot(player)
    local roles = {}
    local journals = {}

    local function pushIfRole(instance)
        if not instance then
            return
        end

        if not isRoleKeyword(instance.Name) then
            return
        end

        local lower = string.lower(instance.Name)
        if string.find(lower, "journal", 1, true) or string.find(lower, "diary", 1, true) or string.find(lower, "notes", 1, true) then
            addEntry(journals, instance.Name, instance)
        else
            addEntry(roles, instance.Name, instance)
        end
    end

    for _, child in ipairs(player:GetChildren()) do
        pushIfRole(child)
    end

    for _, desc in ipairs(player:GetDescendants()) do
        pushIfRole(desc)
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
