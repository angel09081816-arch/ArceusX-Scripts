-- Flicker Role Viewer (rebuild)
-- Fully client-side, mobile-friendly, and no Studio setup required.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer")
local chatHistory = {}
local MAX_CHAT_HISTORY = 150

local ROLE_KEYWORDS = {
    "role", "rank", "title", "team", "faction", "guild", "group", "class", "job",
    "permission", "perm", "access", "authority", "status", "power", "level", "affinity",
    "journal", "diary", "notes", "entry", "log", "memo", "evidence", "report", "archive"
}

local JOURNAL_KEYWORDS = { "journal", "diary", "notes", "entry", "log", "memo", "evidence", "report", "archive" }

local function normalizeText(value)
    if value == nil then
        return ""
    end

    local t = typeof(value)
    if t == "Instance" then
        if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("BoolValue") then
            return tostring(value.Value)
        end
        if value:IsA("Folder") or value:IsA("Model") then
            return value.Name
        end
        return value.Name
    end

    if t == "string" or t == "number" or t == "boolean" then
        return tostring(value)
    end

    return tostring(value)
end

local function containsAny(text, list)
    local lower = string.lower(tostring(text or ""))
    for _, item in ipairs(list) do
        if string.find(lower, item, 1, true) then
            return true
        end
    end
    return false
end

local function isRoleLike(name)
    return containsAny(name, ROLE_KEYWORDS)
end

local function isJournalLike(name)
    return containsAny(name, JOURNAL_KEYWORDS)
end

local function addCandidate(found, name, value)
    local text = normalizeText(value)
    if text ~= "" then
        table.insert(found, { name = name, value = text })
    end
end

local function collectCandidates(target)
    local output = {}
    local seen = {}

    local function push(name, value)
        local key = tostring(name) .. "::" .. tostring(value)
        if not seen[key] then
            seen[key] = true
            addCandidate(output, name, value)
        end
    end

    if not target then
        return output
    end

    for _, child in ipairs(target:GetChildren()) do
        if child:IsA("ValueBase") or child:IsA("Folder") or child:IsA("Model") then
            if isRoleLike(child.Name) or isJournalLike(child.Name) then
                push(child.Name, child)
            end
        end
    end

    for _, desc in ipairs(target:GetDescendants()) do
        if desc:IsA("ValueBase") or desc:IsA("Folder") or desc:IsA("Model") then
            if isRoleLike(desc.Name) or isJournalLike(desc.Name) then
                push(desc.Name, desc)
            end
        end
    end

    for key, value in pairs(target:GetAttributes()) do
        if isRoleLike(key) then
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
                if isRoleLike(stat.Name) or isJournalLike(stat.Name) then
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
                if part:IsA("ValueBase") and (isRoleLike(part.Name) or isJournalLike(part.Name)) then
                    push(part.Name, part.Value)
                end
            end
        end
    end

    return output
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
        local entry = {}
        if serverSnapshot then
            entry = serverSnapshot.players[tostring(player.UserId)] or serverSnapshot.players[player.Name] or {}
        end

        table.insert(snapshot, {
            player = player,
            clientRoles = collectCandidates(player),
            serverRoles = entry.roles or {},
            serverJournals = entry.journals or {},
        })
    end

    return snapshot
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

local function createCard(parent, title, subtitle, lines, accentColor)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -12, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(17, 22, 30)
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

    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0, 18)
    t1.BackgroundTransparency = 1
    t1.Text = title
    t1.TextColor3 = accentColor or Color3.fromRGB(255, 255, 255)
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 13
    t1.Parent = card

    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0, 16)
    t2.Position = UDim2.new(0, 0, 0, 19)
    t2.BackgroundTransparency = 1
    t2.Text = subtitle
    t2.TextColor3 = Color3.fromRGB(180, 188, 200)
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 11
    t2.Parent = card

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

local function recordChat(message)
    if not message or not message.Text or message.Text == "" then
        return
    end

    local speaker = message.Speaker and (message.Speaker.DisplayName or message.Speaker.Name) or "System"
    local channel = message.Channel and message.Channel.Name or "Chat"
    table.insert(chatHistory, 1, {
        speaker = speaker,
        text = tostring(message.Text),
        channel = channel,
        time = os.time(),
    })

    while #chatHistory > MAX_CHAT_HISTORY do
        table.remove(chatHistory)
    end
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
    main.Size = UDim2.new(0, 430, 0, 540)
    main.Position = UDim2.new(0, 14, 0, 14)
    main.BackgroundColor3 = Color3.fromRGB(7, 10, 16)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 78)
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
    subtitle.Size = UDim2.new(1, -28, 0, 40)
    subtitle.Position = UDim2.new(0, 14, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "No Studio script needed. This viewer scans what the client can see and captures live chat in one place."
    subtitle.TextColor3 = Color3.fromRGB(185, 193, 206)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextWrapped = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 34, 0, 34)
    closeButton.Position = UDim2.new(1, -46, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(42, 50, 62)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = main

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -14, 0, 38)
    tabs.Position = UDim2.new(0, 7, 0, 80)
    tabs.BackgroundTransparency = 1
    tabs.Parent = main

    local tabLayout = Instance.new("UIGridLayout")
    tabLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    tabLayout.CellSize = UDim2.new(0, 96, 0, 32)
    tabLayout.StartCorner = Enum.StartCorner.TopLeft
    tabLayout.Parent = tabs

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -14, 1, -128)
    content.Position = UDim2.new(0, 7, 0, 120)
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
        chatsFrame.Visible = name == "Chats"

        for _, child in ipairs(tabs:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = child.Name == name and Color3.fromRGB(69, 104, 255) or Color3.fromRGB(24, 30, 40)
            end
        end
    end

    local function makeTab(name)
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(0, 96, 0, 32)
        tab.BackgroundColor3 = name == "Overview" and Color3.fromRGB(69, 104, 255) or Color3.fromRGB(24, 30, 40)
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
            createCard(overviewFrame, "No players found", "The client is not exposing players yet.", { "Try again after the round starts." }, Color3.fromRGB(130, 220, 255))
            createCard(playersFrame, "Nothing to show", "No player data is visible yet.", { "If the game hides role values, this viewer cannot invent them." }, Color3.fromRGB(130, 220, 255))
            createCard(chatsFrame, "Chat feed", serverAvailable and "Server helper available." or "Client-only chat capture active.", { "Chat messages will appear here as they arrive." }, Color3.fromRGB(130, 220, 255))
            return
        end

        createCard(overviewFrame, "Overview", "What this viewer can read", {
            "Client scan mode: active",
            "Server helper: " .. (serverAvailable and "available" or "not required"),
            "Chat capture: live",
            "Tip: if values are hidden, the viewer shows a safe empty state instead of fake numbers.",
        }, Color3.fromRGB(130, 220, 255))

        for _, entry in ipairs(snapshot) do
            local player = entry.player
            local clientLines = summarize(entry.clientRoles)
            local serverLines = summarize(entry.serverRoles)
            local journalLines = summarize(entry.serverJournals)

            if #clientLines == 0 and #serverLines == 0 and #journalLines == 0 then
                clientLines = { "No obvious role, rank, faction, or journal values were found in this session." }
            end

            local accent = Color3.fromRGB(127, 210, 255)
            local text = string.lower(tostring(player.DisplayName) .. " " .. tostring(player.Name))
            if string.find(text, "evil", 1, true) then
                accent = Color3.fromRGB(255, 120, 120)
            elseif string.find(text, "good", 1, true) then
                accent = Color3.fromRGB(120, 255, 150)
            end

            createCard(playersFrame, player.Name, player.DisplayName .. " | Team: " .. tostring(player.Team and player.Team.Name or "None"), clientLines, accent)

            if #serverLines > 0 then
                createCard(playersFrame, player.Name .. " (server)", "Extra server snapshot values", serverLines, accent)
            end
            if #journalLines > 0 then
                createCard(playersFrame, player.Name .. " (journals)", "Journal-like values", journalLines, accent)
            end
        end

        if #chatHistory > 0 then
            for _, item in ipairs(chatHistory) do
                createCard(chatsFrame, item.speaker, item.channel .. " • " .. os.date("!%H:%M", item.time), { item.text }, Color3.fromRGB(130, 220, 255))
            end
        else
            createCard(chatsFrame, "No chat yet", "Chat capture is active.", { "Messages will appear here when they arrive." }, Color3.fromRGB(130, 220, 255))
        end

        overviewFrame.CanvasSize = UDim2.new(0, 0, 0, overviewLayout.AbsoluteContentSize.Y + 10)
        playersFrame.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10)
        chatsFrame.CanvasSize = UDim2.new(0, 0, 0, chatsLayout.AbsoluteContentSize.Y + 10)
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

    if TextChatService and typeof(TextChatService.OnIncomingMessage) == "RBXScriptSignal" then
        TextChatService.OnIncomingMessage:Connect(function(message)
            pcall(recordChat, message)
        end)
    end

    Players.PlayerChatted:Connect(function(player, message)
        if player and message and message ~= "" then
            pcall(function()
                table.insert(chatHistory, 1, {
                    speaker = player.DisplayName ~= "" and player.DisplayName or player.Name,
                    text = tostring(message),
                    channel = "Chat",
                    time = os.time(),
                })
                while #chatHistory > MAX_CHAT_HISTORY do
                    table.remove(chatHistory)
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
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        createGui()
    end
end)
