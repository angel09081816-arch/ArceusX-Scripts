-- Flicker Role Viewer (clean rebuild)
-- Mobile-friendly and client-side only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer")

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

local function addHint(list, name, value)
    local text = normalizeText(value)
    if text ~= "" then
        table.insert(list, { name = name, value = text })
    end
end

local function collectHints(target)
    local hints = {}
    if not target then
        return hints
    end

    local seen = {}

    local function addUnique(name, value)
        local key = tostring(name) .. "::" .. tostring(value)
        if not seen[key] then
            seen[key] = true
            addHint(hints, name, value)
        end
    end

    for _, child in ipairs(target:GetChildren()) do
        if isRoleKeyword(child.Name) then
            addUnique(child.Name, child)
        end
    end

    for _, desc in ipairs(target:GetDescendants()) do
        if isRoleKeyword(desc.Name) then
            addUnique(desc.Name, desc)
        end
    end

    for key, value in pairs(target:GetAttributes()) do
        if isRoleKeyword(key) then
            addUnique("Attribute:" .. key, value)
        end
    end

    if target:IsA("Player") then
        if target.Team then
            addUnique("Team", target.Team.Name)
        end
        if target.DisplayName then
            addUnique("DisplayName", target.DisplayName)
        end
        local leaderstats = target:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if isRoleKeyword(stat.Name) then
                    addUnique(stat.Name, stat.Value)
                end
            end
        end
    end

    return hints
end

local function getServerSnapshot()
    local remote = ReplicatedStorage:FindFirstChild("FlickerRoleViewerRemote")
    if not remote or typeof(remote.InvokeServer) ~= "function" then
        return nil
    end

    local ok, result = pcall(function()
        return remote:InvokeServer("GetRoleData")
    end)

    if ok and type(result) == "table" and type(result.players) == "table" then
        return result
    end

    return nil
end

local function buildSnapshot()
    local serverSnapshot = getServerSnapshot()
    local out = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local serverData = {}
        if serverSnapshot then
            local entry = serverSnapshot.players[tostring(player.UserId)] or serverSnapshot.players[player.Name]
            if type(entry) == "table" then
                serverData = entry
            end
        end

        table.insert(out, {
            player = player,
            clientHints = collectHints(player),
            serverRoles = serverData.roles or {},
            serverJournals = serverData.journals or {},
        })
    end

    return out
end

local function summarize(list)
    local lines = {}
    for _, item in ipairs(list or {}) do
        if item and item.name and item.value ~= nil then
            table.insert(lines, string.format("%s: %s", tostring(item.name), tostring(item.value)))
        end
    end
    return lines
end

local function makeCard(parent, title, subtitle, lines, accentColor)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -12, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = card

    local line1 = Instance.new("TextLabel")
    line1.Size = UDim2.new(1, 0, 0, 18)
    line1.BackgroundTransparency = 1
    line1.Text = title
    line1.TextColor3 = accentColor or Color3.fromRGB(255, 255, 255)
    line1.TextXAlignment = Enum.TextXAlignment.Left
    line1.Font = Enum.Font.GothamBold
    line1.TextSize = 13
    line1.Parent = card

    local line2 = Instance.new("TextLabel")
    line2.Size = UDim2.new(1, 0, 0, 16)
    line2.Position = UDim2.new(0, 0, 0, 19)
    line2.BackgroundTransparency = 1
    line2.Text = subtitle
    line2.TextColor3 = Color3.fromRGB(180, 188, 200)
    line2.TextXAlignment = Enum.TextXAlignment.Left
    line2.Font = Enum.Font.Gotham
    line2.TextSize = 11
    line2.Parent = card

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 37)
    body.BackgroundTransparency = 1
    body.Text = table.concat(lines or {}, "\n")
    body.TextColor3 = Color3.fromRGB(240, 245, 250)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Font = Enum.Font.Code
    body.TextSize = 11
    body.TextWrapped = true
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = card

    return card
end

local function createGui()
    if not LocalPlayer or not LocalPlayer:FindFirstChild("PlayerGui") then
        return
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("FlickerRoleViewer") then
        playerGui.FlickerRoleViewer:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlickerRoleViewer"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 520)
    main.Position = UDim2.new(0, 14, 0, 14)
    main.BackgroundColor3 = Color3.fromRGB(7, 10, 16)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 24)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Flicker Role Viewer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -28, 0, 36)
    subtitle.Position = UDim2.new(0, 14, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Client-side role and journal scan. Mobile-friendly, simple, and easy to reopen."
    subtitle.TextColor3 = Color3.fromRGB(185, 193, 206)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextWrapped = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 34, 0, 34)
    closeButton.Position = UDim2.new(1, -46, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(38, 46, 58)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = main

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -14, 0, 40)
    tabBar.Position = UDim2.new(0, 7, 0, 80)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local tabLayout = Instance.new("UIGridLayout")
    tabLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    tabLayout.CellSize = UDim2.new(0, 94, 0, 32)
    tabLayout.StartCorner = Enum.StartCorner.TopLeft
    tabLayout.Parent = tabBar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -14, 1, -130)
    content.Position = UDim2.new(0, 7, 0, 120)
    content.BackgroundTransparency = 1
    content.Parent = main

    local overviewFrame = Instance.new("ScrollingFrame")
    overviewFrame.Size = UDim2.new(1, 0, 1, 0)
    overviewFrame.BackgroundTransparency = 1
    overviewFrame.ScrollBarThickness = 5
    overviewFrame.Parent = content

    local overviewLayout = Instance.new("UIListLayout")
    overviewLayout.Padding = UDim.new(0, 8)
    overviewLayout.SortOrder = Enum.SortOrder.LayoutOrder
    overviewLayout.Parent = overviewFrame

    local playersFrame = Instance.new("ScrollingFrame")
    playersFrame.Size = UDim2.new(1, 0, 1, 0)
    playersFrame.BackgroundTransparency = 1
    playersFrame.ScrollBarThickness = 5
    playersFrame.Visible = false
    playersFrame.Parent = content

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim.new(0, 8)
    playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playersLayout.Parent = playersFrame

    local notesFrame = Instance.new("ScrollingFrame")
    notesFrame.Size = UDim2.new(1, 0, 1, 0)
    notesFrame.BackgroundTransparency = 1
    notesFrame.ScrollBarThickness = 5
    notesFrame.Visible = false
    notesFrame.Parent = content

    local notesLayout = Instance.new("UIListLayout")
    notesLayout.Padding = UDim.new(0, 8)
    notesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notesLayout.Parent = notesFrame

    local function clearFrame(frame)
        if not frame then return end
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= frame:FindFirstChildOfClass("UIListLayout") then
                child:Destroy()
            end
        end
    end

    local function setTab(name)
        overviewFrame.Visible = name == "Overview"
        playersFrame.Visible = name == "Players"
        notesFrame.Visible = name == "Notes"

        for _, child in ipairs(tabBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = child.Name == name and Color3.fromRGB(69, 104, 255) or Color3.fromRGB(24, 30, 40)
            end
        end
    end

    local function createTab(name)
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(0, 94, 0, 32)
        tab.BackgroundColor3 = name == "Overview" and Color3.fromRGB(69, 104, 255) or Color3.fromRGB(24, 30, 40)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 11
        tab.AutoButtonColor = true
        tab.Parent = tabBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            setTab(name)
        end)
    end

    createTab("Overview")
    createTab("Players")
    createTab("Notes")

    local function refreshView()
        clearFrame(overviewFrame)
        clearFrame(playersFrame)
        clearFrame(notesFrame)

        local snapshot = buildSnapshot()
        local serverAvailable = getServerSnapshot() ~= nil

        if #snapshot == 0 then
            makeCard(overviewFrame, "No players detected", "The game is not exposing players yet.", { "Try again after players spawn." }, Color3.fromRGB(130, 220, 255))
            makeCard(playersFrame, "No players detected", "The game is not exposing players yet.", { "Try again after players spawn." }, Color3.fromRGB(130, 220, 255))
            makeCard(notesFrame, "Status", serverAvailable and "Server helper is available." or "Running in client-only mode.", { "This viewer reads what the client can see." }, Color3.fromRGB(130, 220, 255))
            return
        end

        local overviewLines = {
            "Client-only scan active.",
            "Server helper: " .. (serverAvailable and "available" or "not found"),
            "Refresh interval: 1 second.",
            "Tip: if you do not see any role values, the game is not exposing them to the client.",
        }
        makeCard(overviewFrame, "Overview", "What this viewer reads", overviewLines, Color3.fromRGB(130, 220, 255))

        for _, entry in ipairs(snapshot) do
            local player = entry.player
            local clientLines = summarize(entry.clientHints)
            local serverLines = summarize(entry.serverRoles)
            local journalLines = summarize(entry.serverJournals)

            if #clientLines == 0 and #serverLines == 0 and #journalLines == 0 then
                clientLines = { "No obvious role or journal values were found in this session." }
            end

            local accent = Color3.fromRGB(120, 210, 255)
            if string.find(string.lower(tostring(player.DisplayName) .. " " .. tostring(player.Name)), "evil", 1, true) then
                accent = Color3.fromRGB(255, 120, 120)
            elseif string.find(string.lower(tostring(player.DisplayName) .. " " .. tostring(player.Name)), "good", 1, true) then
                accent = Color3.fromRGB(120, 255, 150)
            end

            makeCard(playersFrame, player.Name, player.DisplayName .. " | Team: " .. tostring(player.Team and player.Team.Name or "None"), clientLines, accent)

            if #serverLines > 0 then
                makeCard(notesFrame, player.Name .. " (server)", "Server snapshot values", serverLines, accent)
            end
            if #journalLines > 0 then
                makeCard(notesFrame, player.Name .. " (journals)", "Journal-like values", journalLines, accent)
            end
            if #serverLines == 0 and #journalLines == 0 then
                makeCard(notesFrame, player.Name, "No server role data found", { "This usually means the game is not exposing those values to the client." }, accent)
            end
        end

        overviewFrame.CanvasSize = UDim2.new(0, 0, 0, overviewLayout.AbsoluteContentSize.Y + 10)
        playersFrame.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10)
        notesFrame.CanvasSize = UDim2.new(0, 0, 0, notesLayout.AbsoluteContentSize.Y + 10)
    end

    local toggle = Instance.new("TextButton")
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.new(0, 132, 0, 44)
    toggle.Position = UDim2.new(1, -144, 1, -52)
    toggle.BackgroundColor3 = Color3.fromRGB(69, 104, 255)
    toggle.Text = "Open Viewer"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.AutoButtonColor = true
    toggle.Parent = screenGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggle

    closeButton.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    toggle.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    refreshView()
    task.spawn(function()
        while screenGui.Parent do
            task.wait(1)
            pcall(refreshView)
        end
    end)
end

pcall(function()
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        createGui()
    end
end)
