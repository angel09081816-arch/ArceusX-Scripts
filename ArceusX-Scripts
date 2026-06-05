-- Flicker Role Viewer for Arceus X
-- Purpose: shows role-related values that are readable from the client.
-- Safe, client-side only, no remote events or exploit behavior.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local function normalizeText(value)
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

    if typeof(value) == "string" then
        return value
    end

    if typeof(value) == "number" or typeof(value) == "boolean" then
        return tostring(value)
    end

    return tostring(value)
end

local function getRoleCandidateValues(target)
    local found = {}

    if target == nil then
        return found
    end

    local namesToCheck = {
        "Role", "Rank", "Title", "Team", "Faction", "GroupRank", "Permission", "Access", "RoleName",
        "Leaderstats", "playerRole", "PlayerRole", "role", "rank", "title", "team", "faction"
    }

    for _, name in ipairs(namesToCheck) do
        local child = target:FindFirstChild(name)
        if child then
            table.insert(found, {name = name, value = normalizeText(child)})
        end
    end

    if target:IsA("Player") then
        local attrs = target:GetAttributes()
        for key, val in pairs(attrs) do
            local lower = string.lower(key)
            if string.find(lower, "role") or string.find(lower, "rank") or string.find(lower, "team") or string.find(lower, "faction") or string.find(lower, "title") then
                table.insert(found, {name = "Attribute:" .. key, value = normalizeText(val)})
            end
        end
    end

    local leaderstats = target:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local lower = string.lower(stat.Name)
            if string.find(lower, "role") or string.find(lower, "rank") or string.find(lower, "team") or string.find(lower, "faction") or string.find(lower, "title") then
                table.insert(found, {name = stat.Name, value = normalizeText(stat.Value)})
            end
        end
    end

    return found
end

local function buildRoleText()
    local lines = {}
    table.insert(lines, "Flicker Role Viewer")
    table.insert(lines, "Detected player role information (client-readable only):")
    table.insert(lines, "")

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(lines, player.Name .. " (" .. tostring(player.UserId) .. ")")

        local candidates = getRoleCandidateValues(player)
        if #candidates == 0 then
            table.insert(lines, "  No obvious role data found from this client session.")
        else
            for _, item in ipairs(candidates) do
                table.insert(lines, string.format("  %s: %s", item.name, item.value))
            end
        end

        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlickerRoleViewer"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 260)
    main.Position = UDim2.new(0, 18, 0, 18)
    main.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 28)
    title.Position = UDim2.new(0, 8, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Flicker Role Viewer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = main

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -16, 0, 18)
    subtitle.Position = UDim2.new(0, 8, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Client-readable role information only. If the game hides roles server-side, no client script can reveal them fully."
    subtitle.TextColor3 = Color3.fromRGB(180, 190, 210)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextWrapped = true
    subtitle.Parent = main

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -16, 1, -72)
    textBox.Position = UDim2.new(0, 8, 0, 58)
    textBox.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    textBox.TextColor3 = Color3.fromRGB(242, 245, 250)
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.TextWrapped = true
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.Text = "Loading..."
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 12
    textBox.BorderSizePixel = 0
    textBox.Parent = main

    local insideCorner = Instance.new("UICorner")
    insideCorner.CornerRadius = UDim.new(0, 10)
    insideCorner.Parent = textBox

    local function refresh()
        pcall(function()
            textBox.Text = buildRoleText()
        end)
    end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 88, 0, 28)
    button.Position = UDim2.new(1, -96, 1, -34)
    button.BackgroundColor3 = Color3.fromRGB(72, 107, 255)
    button.Text = "Refresh"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.AutoButtonColor = true
    button.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(refresh)

    refresh()
    task.spawn(function()
        while textBox.Parent do
            task.wait(1)
            refresh()
        end
    end)
end

pcall(function()
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        createGui()
    end
end)
