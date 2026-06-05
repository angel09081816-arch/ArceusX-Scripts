-- Fresh Flicker role viewer for Roblox / Arceus X
-- Touch-friendly, client-side, and color-coded for role names.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 30)
local ChatHistory = {}
local MAX_CHAT_HISTORY = 150

local ROLE_HINTS = {
    "role", "rank", "title", "team", "faction", "group", "guild", "class", "job",
    "perm", "permission", "access", "authority", "status", "level", "power", "journal",
    "diary", "notes", "evidence", "archive", "report", "affinity"
}

local function containsAny(text, words)
    local lower = string.lower(tostring(text or ""))
    for _, item in ipairs(words) do
        if string.find(lower, item, 1, true) then
            return true
        end
    end
    return false
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

local function roleAccent(text)
    local lower = string.lower(tostring(text or ""))

    if string.find(lower, "detective", 1, true) or string.find(lower, "savior", 1, true) or string.find(lower, "guardian", 1, true) then
        return Color3.fromRGB(92, 180, 255)
    end

    if string.find(lower, "clown", 1, true) then
        return Color3.fromRGB(180, 180, 180)
    end

    if string.find(lower, "murderer", 1, true) or string.find(lower, "killer", 1, true) or string.find(lower, "evil", 1, true) or string.find(lower, "cult", 1, true) then
        return Color3.fromRGB(255, 104, 104)
    end

    return Color3.fromRGB(130, 220, 255)
end

local function collectRoleHints(target)
    local out = {}
    local seen = {}

    local function push(name, value)
        local key = tostring(name) .. "::" .. tostring(value)
        if not seen[key] then
            seen[key] = true
            local text = normalizeValue(value)
            if text ~= "" then
                table.insert(out, { name = tostring(name), value = text })
            end
        end
    end

    if not target then
        return out
    end

    for _, child in ipairs(target:GetChildren()) do
        if child:IsA("ValueBase") or child:IsA("Folder") or child:IsA("Model") then
            if containsAny(child.Name, ROLE_HINTS) then
                push(child.Name, child)
            end
        end
    end

    for _, desc in ipairs(target:GetDescendants()) do
        if desc:IsA("ValueBase") or desc:IsA("Folder") or desc:IsA("Model") then
            if containsAny(desc.Name, ROLE_HINTS) then
                push(desc.Name, desc)
            end
        end
    end

    for key, value in pairs(target:GetAttributes()) do
        if containsAny(key, ROLE_HINTS) then
            push("Attribute:" .. key, value)
        end
    end

    if target:IsA("Player") then
        if target.Team then
            push("Team", target.Team.Name)
        end

        if target.DisplayName and target.DisplayName ~= "" then
            push("DisplayName", target.DisplayName)
        end

        local leaderstats = target:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if containsAny(stat.Name, ROLE_HINTS) then
                    push(stat.Name, stat.Value)
                end
            end
        end

        local character = target.Character or target:FindFirstChildOfClass("Model")
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                push("Health", humanoid.Health)
                push("MaxHealth", humanoid.MaxHealth)
            end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("ValueBase") and containsAny(part.Name, ROLE_HINTS) then
                    push(part.Name, part.Value)
                end
            end
        end
    end

    return out
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
    local snapshot = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local extra = {}
        if serverSnapshot and serverSnapshot.players then
            extra = serverSnapshot.players[tostring(player.UserId)] or serverSnapshot.players[player.Name] or {}
        end

        table.insert(snapshot, {
            player = player,
            clientHints = collectRoleHints(player),
            serverHints = extra.roles or {},
            journalHints = extra.journals or {},
        })
    end

    return snapshot
end

local function summarize(list)
    local lines = {}
    for _, item in ipairs(list or {}) do
        if item and item.name and item.value ~= nil then
            table.insert(lines, tostring(item.name) .. ": " .. tostring(item.value))
        end
    end
    return lines
end

local function createCard(parent, title, subtitle, lines, accent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
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

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = accent or Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.Parent = card

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 20)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(185, 194, 208)
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 11
    subtitleLabel.TextWrapped = true
    subtitleLabel.Parent = card

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 40)
    body.BackgroundTransparency = 1
    body.Text = table.concat(lines or {}, "\n")
    body.TextColor3 = Color3.fromRGB(245, 248, 252)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Font = Enum.Font.Code
    body.TextSize = 11
    body.TextWrapped = true
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = card

    return card
end

local function recordChat(message)
    if not message or not message.Text or tostring(message.Text) == "" then
        return
    end

    local speaker = message.Speaker and (message.Speaker.DisplayName or message.Speaker.Name) or "System"
    local channel = message.Channel and message.Channel.Name or "Chat"

    table.insert(ChatHistory, 1, {
        speaker = speaker,
        text = tostring(message.Text),
        channel = channel,
        time = os.time(),
    })

    while #ChatHistory > MAX_CHAT_HISTORY do
        table.remove(ChatHistory)
    end
end

local function getGuiParent()
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        return LocalPlayer.PlayerGui
    end
    return CoreGui
end

local function createGui()
    if not LocalPlayer then
        return
    end

    local guiParent = getGuiParent()
    if not guiParent then
        return
    end

    local existing = guiParent:FindFirstChild("FlickerRoleViewer")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlickerRoleViewer"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = guiParent

    local isMobile = UserInputService.TouchEnabled or (UserInputService.GetDeviceFamily and UserInputService:GetDeviceFamily() == Enum.DeviceFamily.Phone)

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = isMobile and UDim2.new(1, -12, 0, 430) or UDim2.new(0, 430, 0, 540)
    main.Position = isMobile and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 14, 0, 14)
    main.BackgroundColor3 = Color3.fromRGB(7, 10, 16)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 82)
    header.BackgroundTransparency = 1
    header.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -86, 0, 24)
    title.Position = UDim2.new(0, 12, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Flicker Role Viewer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = isMobile and 15 or 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -28, 0, 42)
    subtitle.Position = UDim2.new(0, 12, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Fresh Flicker-style role scan with live chat and role-color names."
    subtitle.TextColor3 = Color3.fromRGB(187, 194, 206)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = isMobile and 10 or 11
    subtitle.TextWrapped = true
    subtitle.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -48, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(33, 39, 49)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = main

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 9)
    closeCorner.Parent = closeButton

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -14, 0, 40)
    tabs.Position = UDim2.new(0, 7, 0, 82)
    tabs.BackgroundTransparency = 1
    tabs.Parent = main

    local tabLayout = Instance.new("UIGridLayout")
    tabLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    tabLayout.CellSize = isMobile and UDim2.new(0, 88, 0, 32) or UDim2.new(0, 96, 0, 32)
    tabLayout.StartCorner = Enum.StartCorner.TopLeft
    tabLayout.Parent = tabs

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -14, 1, -132)
    content.Position = UDim2.new(0, 7, 0, 124)
    content.BackgroundTransparency = 1
    content.Parent = main

    local overviewFrame = Instance.new("ScrollingFrame")
    overviewFrame.Size = UDim2.new(1, 0, 1, 0)
    overviewFrame.BackgroundTransparency = 1
    overviewFrame.ScrollBarThickness = 5
    overviewFrame.Parent = content

    local overviewLayout = Instance.new("UIListLayout")
    overviewLayout.Padding = UDim2.new(0, 8)
    overviewLayout.SortOrder = Enum.SortOrder.LayoutOrder
    overviewLayout.Parent = overviewFrame

    local playersFrame = Instance.new("ScrollingFrame")
    playersFrame.Size = UDim2.new(1, 0, 1, 0)
    playersFrame.BackgroundTransparency = 1
    playersFrame.ScrollBarThickness = 5
    playersFrame.Visible = false
    playersFrame.Parent = content

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim2.new(0, 8)
    playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playersLayout.Parent = playersFrame

    local chatsFrame = Instance.new("ScrollingFrame")
    chatsFrame.Size = UDim2.new(1, 0, 1, 0)
    chatsFrame.BackgroundTransparency = 1
    chatsFrame.ScrollBarThickness = 5
    chatsFrame.Visible = false
    chatsFrame.Parent = content

    local chatsLayout = Instance.new("UIListLayout")
    chatsLayout.Padding = UDim2.new(0, 8)
    chatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatsLayout.Parent = chatsFrame

    local function clearFrame(frame)
        if not frame then
            return
        end
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= frame:FindFirstChildOfClass("UIListLayout") then
                child:Destroy()
            end
        end
    end

    local function setTab(name)
        overviewFrame.Visible = name == "Overview"
        playersFrame.Visible = name == "Players"
        chatsFrame.Visible = name == "Chats"

        for _, child in ipairs(tabs:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = child.Name == name and Color3.fromRGB(75, 116, 255) or Color3.fromRGB(24, 30, 40)
            end
        end
    end

    local function makeTab(name)
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(0, isMobile and 88 or 96, 0, 32)
        tab.BackgroundColor3 = name == "Overview" and Color3.fromRGB(75, 116, 255) or Color3.fromRGB(24, 30, 40)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 11
        tab.AutoButtonColor = true
        tab.Parent = tabs

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            setTab(name)
        end)
    end

    makeTab("Overview")
    makeTab("Players")
    makeTab("Chats")

    local function refreshView()
        clearFrame(overviewFrame)
        clearFrame(playersFrame)
        clearFrame(chatsFrame)

        local snapshot = buildSnapshot()
        local serverAvailable = getServerSnapshot() ~= nil

        if #snapshot == 0 then
            createCard(overviewFrame, "No players found", "The game is not exposing players to the client yet.", { "Try again after the round starts." }, Color3.fromRGB(130, 220, 255))
            createCard(playersFrame, "Nothing to show", "No role data is visible yet.", { "This viewer only reads what the client can see." }, Color3.fromRGB(130, 220, 255))
            createCard(chatsFrame, "Chat feed", serverAvailable and "Server helper available." or "Live chat capture is active.", { "Messages will appear here as they arrive." }, Color3.fromRGB(130, 220, 255))
            return
        end

        createCard(overviewFrame, "Overview", "Fresh Flicker-style viewer", {
            "Role scan: active",
            "Server helper: " .. (serverAvailable and "available" or "optional"),
            "Chat capture: live",
            "Role name colors: detective/savior = blue, murderer/evil = red, clown = grey"
        }, Color3.fromRGB(130, 220, 255))

        for _, entry in ipairs(snapshot) do
            local player = entry.player
            local clientLines = summarize(entry.clientHints)
            local serverLines = summarize(entry.serverHints)
            local journalLines = summarize(entry.journalHints)
            local accent = roleAccent(player.DisplayName .. " " .. player.Name)
            local fallback = roleAccent(table.concat(clientLines, " "))
            if fallback ~= nil then
                accent = fallback
            end

            if #clientLines == 0 and #serverLines == 0 and #journalLines == 0 then
                clientLines = { "No obvious role, rank, faction, or journal values were found in this session." }
            end

            createCard(playersFrame, player.Name, tostring(player.DisplayName) .. " | Team: " .. tostring(player.Team and player.Team.Name or "None"), clientLines, accent)

            if #serverLines > 0 then
                createCard(playersFrame, player.Name .. " (server)", "Extra server snapshot values", serverLines, accent)
            end

            if #journalLines > 0 then
                createCard(playersFrame, player.Name .. " (journals)", "Journal-like values", journalLines, accent)
            end
        end

        if #ChatHistory > 0 then
            for _, item in ipairs(ChatHistory) do
                createCard(chatsFrame, item.speaker, item.channel .. " • " .. os.date("!%H:%M", item.time), { item.text }, roleAccent(item.speaker))
            end
        else
            createCard(chatsFrame, "No chat yet", "Chat capture is active.", { "Messages will appear here as they arrive." }, Color3.fromRGB(130, 220, 255))
        end

        overviewFrame.CanvasSize = UDim2.new(0, 0, 0, overviewLayout.AbsoluteContentSize.Y + 10)
        playersFrame.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10)
        chatsFrame.CanvasSize = UDim2.new(0, 0, 0, chatsLayout.AbsoluteContentSize.Y + 10)
    end

    local toggle = Instance.new("TextButton")
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.new(0, isMobile and 150 or 148, 0, 44)
    toggle.Position = UDim2.new(1, -162, 1, -56)
    toggle.BackgroundColor3 = Color3.fromRGB(75, 116, 255)
    toggle.Text = "Open Viewer"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = isMobile and 12 or 13
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
        if main.Visible then
            refreshView()
        end
    end)

    if TextChatService and typeof(TextChatService.OnIncomingMessage) == "RBXScriptSignal" then
        TextChatService.OnIncomingMessage:Connect(function(message)
            pcall(recordChat, message)
        end)
    end

    Players.PlayerChatted:Connect(function(player, message)
        if player and message and tostring(message) ~= "" then
            pcall(function()
                table.insert(ChatHistory, 1, {
                    speaker = player.DisplayName ~= "" and player.DisplayName or player.Name,
                    text = tostring(message),
                    channel = "Chat",
                    time = os.time(),
                })
                while #ChatHistory > MAX_CHAT_HISTORY do
                    table.remove(ChatHistory)
                end
            end)
        end
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
    if LocalPlayer then
        createGui()
    end
end)
