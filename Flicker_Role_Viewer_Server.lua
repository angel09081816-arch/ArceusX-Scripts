-- Flicker Role Viewer server helper
-- Place this in ServerScriptService.
-- It exposes a remote snapshot of player role/journal-like values to the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function normalizeValue(value)
    if value == nil then
        return ""
    end

    if typeof(value) == "Instance" then
        if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("BoolValue") then
            return tostring(value.Value)
        end

        if value:IsA("Folder") or value:IsA("Model") then
            return value.Name
        end
        return value.Name
    end

    if typeof(value) == "string" or typeof(value) == "number" or typeof(value) == "boolean" then
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
end

local function collectServerEntries(player)
    local roles = {}
    local journals = {}

    for _, child in ipairs(player:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") or child:IsA("ValueBase") then
            if isRoleLikeName(child.Name) then
                table.insert(roles, { name = child.Name, value = normalizeValue(child) })
            end
        end
    end

    for _, descendant in ipairs(player:GetDescendants()) do
        if descendant:IsA("ValueBase") or descendant:IsA("Folder") or descendant:IsA("Model") then
            if isRoleLikeName(descendant.Name) then
                if string.find(string.lower(descendant.Name), "journal") or string.find(string.lower(descendant.Name), "diary") then
                    table.insert(journals, { name = descendant.Name, value = normalizeValue(descendant) })
                else
                    table.insert(roles, { name = descendant.Name, value = normalizeValue(descendant) })
                end
            end
        end
    end

    for key, value in pairs(player:GetAttributes()) do
        if isRoleLikeName(key) then
            table.insert(roles, { name = "Attribute:" .. key, value = normalizeValue(value) })
        end
    end

    if player.Team then
        table.insert(roles, { name = "Team", value = player.Team.Name })
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if isRoleLikeName(stat.Name) then
                table.insert(roles, { name = stat.Name, value = normalizeValue(stat.Value) })
            end
        end
    end

    if player:GetRankInGroup(1) ~= nil then
        -- Keep this harmless; the client only receives what is already visible server-side.
    end

    return {
        roles = roles,
        journals = journals,
    }
end

local remote = ReplicatedStorage:FindFirstChild("FlickerRoleViewerRemote")
if remote then
    remote:Destroy()
end

local newRemote = Instance.new("RemoteFunction")
newRemote.Name = "FlickerRoleViewerRemote"
newRemote.Parent = ReplicatedStorage

newRemote.OnServerInvoke = function(player, action)
    if action ~= "GetRoleData" then
        return nil
    end

    local snapshot = { players = {} }
    for _, other in ipairs(Players:GetPlayers()) do
        snapshot.players[tostring(other.UserId)] = collectServerEntries(other)
    end

    return snapshot
end

Players.PlayerAdded:Connect(function(player)
    -- No-op; the client asks for the data on demand.
end)
