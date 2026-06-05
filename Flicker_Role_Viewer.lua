-- Flicker Role Viewer for Arceus X
-- Purpose: shows player roles, teams, journals, and client/server-readable values in a polished UI.
-- Safe, client-side by default, with an optional server-side snapshot for richer data.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

local function addCandidate(found, name, value)
    if value ~= nil and tostring(value) ~= "" then
        table.insert(found, { name = name, value = normalizeText(value) })
    end
end

local function collectClientCandidates(target)
    local found = {}

    if target == nil then
        return found
    end

    local namesToCheck = {
        "Role", "Rank", "Title", "Team", "Faction", "GroupRank", "Permission", "Access", "RoleName",
        "Journal", "JournalEntry", "Diary", "Notes", "Leaderstats", "playerRole", "PlayerRole",
        "role", "rank", "title", "team", "faction", "journal", "diary"
    }

    for _, name in ipairs(namesToCheck) do
        local child = target:FindFirstChild(name)
        if child then
            addCandidate(found, name, child)
        end
    end

    for _, descendant in ipairs(target:GetDescendants()) do
        if descendant:IsA("ValueBase") or descendant:IsA("Folder") or descendant:IsA("Model") then
            if isRoleLikeName(descendant.Name) then
                addCandidate(found, descendant.Name, descendant)
            end
        end
    end

    if target:IsA("Player") then
        for key, val in pairs(target:GetAttributes()) do
            if isRoleLikeName(key) then
                addCandidate(found, "Attribute:" .. key, val)
            end
        end

        if target.Team then
            addCandidate(found, "Team", target.Team)
            addCandidate(found, "Team.Name", target.Team.Name)
            addCandidate(found, "TeamColor", target.TeamColor)
        end

        if target.Character then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                addCandidate(found, "DisplayName", target.DisplayName)
                addCandidate(found, "Health", humanoid.Health)
                addCandidate(found, "MaxHealth", humanoid.MaxHealth)
            end
        end
    end

    local leaderstats = target:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if isRoleLikeName(stat.Name) then
                addCandidate(found, stat.Name, stat.Value)
            end
        end
    end

    return found
end

local function getServerSnapshot()
    local remote = ReplicatedStorage:FindFirstChild("FlickerRoleViewerRemote")
    if not remote or typeof(remote.InvokeServer) ~= "function" then
        return nil
    end

    local ok, result = pcall(function()
        return remote:InvokeServer("GetRoleData")
    end)

    if ok and type(result) == "table" then
        return result
    end

    return nil
end

local function buildPlayerSnapshot()
    local serverSnapshot = getServerSnapshot()
    local players = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local clientCandidates = collectClientCandidates(player)
        local serverCandidates = {}
        local serverJournals = {}

        if serverSnapshot and type(serverSnapshot.players) == "table" then
            local entry = serverSnapshot.players[tostring(player.UserId)] or serverSnapshot.players[player.Name]
            if entry then
                serverCandidates = entry.roles or {}
                serverJournals = entry.journals or {}
            end
        end

        table.insert(players, {
            player = player,
            clientRoles = clientCandidates,
            serverRoles = serverCandidates,
            journals = serverJournals,
        })
    end

    return players
end

local function summarizeCandidates(list)
    local output = {}
    for _, item in ipairs(list or {}) do
        table.insert(output, string.format("%s: %s", item.name, item.value))
    end
    return output
end

local function createCard(parent, title, subtitle, lines)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -18, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim2.new(0, 10)
    padding.PaddingRight = UDim2.new(0, 10)
    padding.PaddingTop = UDim2.new(0, 10)
    padding.PaddingBottom = UDim2.new(0, 10)
    padding.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.Parent = card

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 18)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(170, 180, 200)
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 11
    subtitleLabel.Parent = card

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 38)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = table.concat(lines, "\n")
    textLabel.TextColor3 = Color3.fromRGB(235, 240, 248)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Font = Enum.Font.Code
    textLabel.TextSize = 11
    textLabel.TextWrapped = true
    textLabel.RichText = false
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Parent = card

    return card
end

local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlickerRoleViewer"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 560, 0, 440)
    main.Position = UDim2.new(0, 18, 0, 18)
    main.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 72)
    header.BackgroundTransparency = 1
    header.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 24)
    title.Position = UDim2.new(0, 16, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Flicker Role Viewer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -32, 0, 28)
    subtitle.Position = UDim2.new(0, 16, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Roles, journals, and player info in one scrollable view. Server data is used when available."
    subtitle.TextColor3 = Color3.fromRGB(185, 194, 210)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextWrapped = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Parent = header

    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, 0, 0, 72)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Active = true
    dragHandle.Selectable = true
    dragHandle.ZIndex = 5
    dragHandle.Parent = main

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 32, 0, 32)
    closeButton.Position = UDim2.new(1, -42, 0, 12)
    closeButton.BackgroundColor3 = Color3.fromRGB(52, 60, 74)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.AutoButtonColor = true
    closeButton.Parent = main

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -18, 0, 40)
    tabBar.Position = UDim2.new(0, 9, 0, 72)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local tabs = {}
    local activeTab = "Roles"

    local function createTab(name)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 110, 0, 32)
        tab.BackgroundColor3 = name == activeTab and Color3.fromRGB(72, 107, 255) or Color3.fromRGB(25, 30, 40)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 12
        tab.AutoButtonColor = true
        tab.Parent = tabBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            activeTab = name
            for _, other in ipairs(tabs) do
                other.Button.BackgroundColor3 = other.Name == activeTab and Color3.fromRGB(72, 107, 255) or Color3.fromRGB(25, 30, 40)
            end
            rolesFrame.Visible = activeTab == "Roles"
            journalsFrame.Visible = activeTab == "Journals"
            summaryFrame.Visible = activeTab == "Summary"
        end)

        return { Name = name, Button = tab }
    end

    table.insert(tabs, createTab("Roles"))
    table.insert(tabs, createTab("Journals"))
    table.insert(tabs, createTab("Summary"))

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -18, 1, -122)
    content.Position = UDim2.new(0, 9, 0, 112)
    content.BackgroundTransparency = 1
    content.Parent = main

    local rolesFrame = Instance.new("ScrollingFrame")
    rolesFrame.Name = "RolesFrame"
    rolesFrame.Size = UDim2.new(1, 0, 1, 0)
    rolesFrame.BackgroundTransparency = 1
    rolesFrame.BorderSizePixel = 0
    rolesFrame.ScrollBarThickness = 6
    rolesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    rolesFrame.Parent = content

    local rolesLayout = Instance.new("UIListLayout")
    rolesLayout.Padding = UDim.new(0, 8)
    rolesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rolesLayout.Parent = rolesFrame

    local journalsFrame = Instance.new("ScrollingFrame")
    journalsFrame.Name = "JournalsFrame"
    journalsFrame.Size = UDim2.new(1, 0, 1, 0)
    journalsFrame.BackgroundTransparency = 1
    journalsFrame.BorderSizePixel = 0
    journalsFrame.ScrollBarThickness = 6
    journalsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    journalsFrame.Visible = false
    journalsFrame.Parent = content

    local journalsLayout = Instance.new("UIListLayout")
    journalsLayout.Padding = UDim.new(0, 8)
    journalsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    journalsLayout.Parent = journalsFrame

    local summaryFrame = Instance.new("ScrollingFrame")
    summaryFrame.Name = "SummaryFrame"
    summaryFrame.Size = UDim2.new(1, 0, 1, 0)
    summaryFrame.BackgroundTransparency = 1
    summaryFrame.BorderSizePixel = 0
    summaryFrame.ScrollBarThickness = 6
    summaryFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    summaryFrame.Visible = false
    summaryFrame.Parent = content

    local summaryLayout = Instance.new("UIListLayout")
    summaryLayout.Padding = UDim.new(0, 8)
    summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    summaryLayout.Parent = summaryFrame

    local function clearFrame(frame)
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("UIListLayout") then
                continue
            end
            child:Destroy()
        end
    end

    local function refreshView()
        clearFrame(rolesFrame)
        clearFrame(journalsFrame)
        clearFrame(summaryFrame)

        rolesLayout.Parent = rolesFrame
        journalsLayout.Parent = journalsFrame
        summaryLayout.Parent = summaryFrame

        local snapshot = buildPlayerSnapshot()
        local hasServer = getServerSnapshot() ~= nil

        if #snapshot == 0 then
            createCard(rolesFrame, "No players found", "The server is not exposing players to this client session right now.", { "Try refreshing after players spawn in." })
            createCard(journalsFrame, "No journals found", "No journal-like values were found on this client session.", { "Server-side journals will appear if the game exposes them." })
            createCard(summaryFrame, "Status", hasServer and "Server snapshot available." or "Client-only scan active.", { "Role values are read from the client and any available server snapshot." })
            return
        end

        for _, entry in ipairs(snapshot) do
            local player = entry.player
            local roleLines = summarizeCandidates(entry.clientRoles)
            local serverLines = summarizeCandidates(entry.serverRoles)
            local journalLines = summarizeCandidates(entry.journals)

            if #roleLines == 0 and #serverLines == 0 then
                table.insert(roleLines, "No obvious role data found from this client session.")
            end

            if #serverLines > 0 then
                for _, line in ipairs(serverLines) do
                    table.insert(roleLines, "[Server] " .. line)
                end
            end

            if #roleLines > 0 then
                createCard(rolesFrame, player.Name .. "  •  " .. tostring(player.UserId), player.DisplayName .. " | Team: " .. tostring(player.Team and player.Team.Name or "None"), roleLines)
            else
                createCard(rolesFrame, player.Name .. "  •  " .. tostring(player.UserId), "No role data to show yet.", { "Refresh again or wait for the game to expose leaderstats/attributes." })
            end

            if #journalLines > 0 then
                createCard(journalsFrame, player.Name .. "  •  " .. tostring(player.UserId), player.DisplayName, journalLines)
            else
                createCard(journalsFrame, player.Name .. "  •  " .. tostring(player.UserId), "No journal-like data found.", { "If the game stores journals in a different name, they may not be visible to the client." })
            end

            local stats = {
                "DisplayName: " .. tostring(player.DisplayName),
                "Team: " .. tostring(player.Team and player.Team.Name or "None"),
                "UserId: " .. tostring(player.UserId),
                "Client role entries: " .. tostring(#entry.clientRoles),
                "Server role entries: " .. tostring(#entry.serverRoles),
                "Journal entries: " .. tostring(#entry.journals),
            }
            createCard(summaryFrame, player.Name, "Quick player summary", stats)
        end

        rolesFrame.CanvasSize = UDim2.new(0, 0, 0, rolesLayout.AbsoluteContentSize.Y + 18)
        journalsFrame.CanvasSize = UDim2.new(0, 0, 0, journalsLayout.AbsoluteContentSize.Y + 18)
        summaryFrame.CanvasSize = UDim2.new(0, 0, 0, summaryLayout.AbsoluteContentSize.Y + 18)
    end

    local function setMenuVisible(visible)
        main.Visible = visible
    end

    closeButton.MouseButton1Click:Connect(function()
        setMenuVisible(false)
    end)

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 126, 0, 42)
    toggleButton.Position = UDim2.new(1, -140, 1, -56)
    toggleButton.BackgroundColor3 = Color3.fromRGB(72, 107, 255)
    toggleButton.Text = "Open Viewer"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 12
    toggleButton.AutoButtonColor = true
    toggleButton.Parent = screenGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleButton

    local dragData = {}
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData.toggle = true
            dragData.startPos = input.Position
            dragData.startButtonPos = toggleButton.Position
        end
    end)

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData.main = true
            dragData.startPos = input.Position
            dragData.startMainPos = main.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData = {}
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragData.startPos then
            local delta = input.Position - dragData.startPos
            if dragData.toggle then
                toggleButton.Position = UDim2.new(dragData.startButtonPos.X.Scale, dragData.startButtonPos.X.Offset + delta.X, dragData.startButtonPos.Y.Scale, dragData.startButtonPos.Y.Offset + delta.Y)
            end
            if dragData.main then
                main.Position = UDim2.new(dragData.startMainPos.X.Scale, dragData.startMainPos.X.Offset + delta.X, dragData.startMainPos.Y.Scale, dragData.startMainPos.Y.Offset + delta.Y)
            end
        end
    end)

    toggleButton.MouseButton1Click:Connect(function()
        if not (dragData.toggle and dragData.startPos) then
            setMenuVisible(not main.Visible)
        end
    end)

    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 96, 0, 32)
    refreshButton.Position = UDim2.new(1, -108, 0, 12)
    refreshButton.BackgroundColor3 = Color3.fromRGB(42, 52, 68)
    refreshButton.Text = "Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 12
    refreshButton.AutoButtonColor = true
    refreshButton.Parent = main

    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton

    refreshButton.MouseButton1Click:Connect(refreshView)

    refreshView()
    task.spawn(function()
        while main.Parent do
            task.wait(1)
            refreshView()
        end
    end)
end

pcall(function()
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        createGui()
    end
end)
