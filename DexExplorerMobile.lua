-- ============================================================
-- DEX EXPLORER MOBILE | Script único para Roblox
-- Compatível com: Arceus X, Hydrogen, Delta e similares
-- Construído apenas com Instance.new | Sem dependências externas
-- ============================================================

local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

-- ── Utilitários de executor ──────────────────────────────────

-- Tenta obter a GUI raiz sem conflito com o CoreGui protegido
local function getRoot()
    if gethui then return gethui() end
    local ok, g = pcall(function() return game:GetService("CoreGui") end)
    return ok and g or Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Tenta descompilar um script usando funções do executor disponíveis
local function tryDecompile(inst)
    -- tentativa 1: syn.crypt.decompile
    if syn and syn.crypt and syn.crypt.decompile then
        local ok, r = pcall(syn.crypt.decompile, inst)
        if ok and r and #r > 0 then return r end
    end
    -- tentativa 2: decompile global
    if decompile then
        local ok, r = pcall(decompile, inst)
        if ok and r and #r > 0 then return r end
    end
    -- tentativa 3: getscriptbytecode (retorna bytecode bruto)
    if getscriptbytecode then
        local ok, bytes = pcall(getscriptbytecode, inst)
        if ok and bytes and #bytes > 0 then
            return "-- [Bytecode disponível mas sem decompilador ativo]\n-- Use um executor com suporte a decompile()."
        end
    end
    return nil -- falha total
end

-- Copia texto para a área de transferência com fallback
local function copyText(text, popupFrame)
    if setclipboard then
        pcall(setclipboard, text)
    elseif toclipboard then
        pcall(toclipboard, text)
    else
        -- fallback: mostrar no popup
        if popupFrame then popupFrame.Visible = true end
        return false
    end
    return true
end

-- Obtém o nome "real" de uma instância contornando proteções
local function getRealName(inst)
    local name = inst.Name
    -- prioridade 1: atributo RealName
    local ok1, attr = pcall(function() return inst:GetAttribute("RealName") end)
    if ok1 and attr and #tostring(attr) > 0 then return tostring(attr), false end
    -- prioridade 2: filho chamado RealName
    local ok2, child = pcall(function() return inst:FindFirstChild("RealName") end)
    if ok2 and child then return child.Value or name, false end
    -- prioridade 3: GetFullName() → último segmento
    local ok3, full = pcall(function() return inst:GetFullName() end)
    if ok3 and full then
        local seg = full:match("([^%.]+)$")
        if seg and seg ~= name then return seg, false end
    end
    return name, (name == "" or name:match("^%d"))  -- aviso se suspeito
end

-- Gera lista indentada de descendentes recursivamente
local function buildChildList(inst, depth, lines)
    lines = lines or {}
    depth = depth or 0
    local ok, children = pcall(function() return inst:GetChildren() end)
    if not ok then return lines end
    for _, child in ipairs(children) do
        local realName = getRealName(child)
        table.insert(lines, string.rep("  ", depth) .. realName .. " (" .. child.ClassName .. ")")
        buildChildList(child, depth + 1, lines)
    end
    return lines
end

-- ── Constantes de layout ─────────────────────────────────────

local DARK   = Color3.fromRGB(22, 22, 28)
local PANEL  = Color3.fromRGB(30, 30, 38)
local ACCENT = Color3.fromRGB(90, 160, 255)
local TEXT   = Color3.fromRGB(220, 220, 230)
local MUTED  = Color3.fromRGB(120, 120, 140)
local GREEN  = Color3.fromRGB(80, 200, 120)
local RED    = Color3.fromRGB(220, 80, 80)
local INDENT = 14  -- px por nível de profundidade na árvore

-- ── Fábrica de instâncias ────────────────────────────────────

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- ── Construção da GUI ────────────────────────────────────────

local root = getRoot()

-- Remove instância anterior para evitar duplicatas ao re-injetar
local prev = root:FindFirstChild("DexExplorerMobile")
if prev then prev:Destroy() end

local screenGui = make("ScreenGui", {
    Name            = "DexExplorerMobile",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset  = true,
}, root)

-- ── Botão flutuante (toggle) ─────────────────────────────────

local toggleBtn = make("TextButton", {
    Size            = UDim2.new(0, 52, 0, 52),
    Position        = UDim2.new(0, 12, 0.5, -26),
    BackgroundColor3 = ACCENT,
    Text            = "DEX",
    TextColor3      = Color3.new(1,1,1),
    Font            = Enum.Font.GothamBold,
    TextSize        = 11,
    BorderSizePixel = 0,
    ZIndex          = 10,
}, screenGui)
make("UICorner", {CornerRadius = UDim.new(1,0)}, toggleBtn)

-- ── Painel principal ─────────────────────────────────────────

local mainFrame = make("Frame", {
    Name            = "MainFrame",
    Size            = UDim2.new(1, 0, 1, 0),
    Position        = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = DARK,
    BorderSizePixel = 0,
    Visible         = false,
    ZIndex          = 5,
}, screenGui)

-- Barra de título
local titleBar = make("Frame", {
    Size            = UDim2.new(1,0,0,44),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex          = 6,
}, mainFrame)

make("TextLabel", {
    Size            = UDim2.new(1,-110,1,0),
    Position        = UDim2.new(0,12,0,0),
    BackgroundTransparency = 1,
    Text            = "⬡ Dex Explorer",
    TextColor3      = ACCENT,
    Font            = Enum.Font.GothamBold,
    TextSize        = 16,
    TextXAlignment  = Enum.TextXAlignment.Left,
    ZIndex          = 7,
}, titleBar)

-- Botão Refresh
local refreshBtn = make("TextButton", {
    Size            = UDim2.new(0,70,0,30),
    Position        = UDim2.new(1,-84,0,7),
    BackgroundColor3 = PANEL,
    Text            = "↺ Refresh",
    TextColor3      = MUTED,
    Font            = Enum.Font.Gotham,
    TextSize        = 12,
    BorderSizePixel = 0,
    ZIndex          = 7,
}, titleBar)
make("UICorner", {CornerRadius = UDim.new(0,6)}, refreshBtn)

-- Botão Fechar
local closeBtn = make("TextButton", {
    Size            = UDim2.new(0,32,0,32),
    Position        = UDim2.new(1,-38,0,6),
    BackgroundColor3 = RED,
    Text            = "✕",
    TextColor3      = Color3.new(1,1,1),
    Font            = Enum.Font.GothamBold,
    TextSize        = 14,
    BorderSizePixel = 0,
    ZIndex          = 7,
}, titleBar)
make("UICorner", {CornerRadius = UDim.new(0,6)}, closeBtn)

-- ── Área da árvore (metade superior) ────────────────────────

local treeArea = make("Frame", {
    Size            = UDim2.new(1,0,0.5,-44),
    Position        = UDim2.new(0,0,0,44),
    BackgroundColor3 = DARK,
    BorderSizePixel = 0,
    ZIndex          = 5,
}, mainFrame)

local treeScroll = make("ScrollingFrame", {
    Size                  = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    BorderSizePixel       = 0,
    ScrollBarThickness    = 4,
    ScrollBarImageColor3  = ACCENT,
    CanvasSize            = UDim2.new(0,0,0,0),
    ZIndex                = 6,
}, treeArea)

local treeLayout = make("UIListLayout", {
    SortOrder   = Enum.SortOrder.LayoutOrder,
    Padding     = UDim.new(0, 1),
}, treeScroll)

-- ── Divisor ──────────────────────────────────────────────────

make("Frame", {
    Size            = UDim2.new(1,0,0,2),
    Position        = UDim2.new(0,0,0.5,-2),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
    ZIndex          = 6,
}, mainFrame)

-- ── Painel de detalhes (metade inferior) ─────────────────────

local detailArea = make("Frame", {
    Size            = UDim2.new(1,0,0.5,0),
    Position        = UDim2.new(0,0,0.5,0),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex          = 5,
}, mainFrame)

-- Abas do painel de detalhes
local tabBar = make("Frame", {
    Size            = UDim2.new(1,0,0,36),
    BackgroundColor3 = DARK,
    BorderSizePixel = 0,
    ZIndex          = 6,
}, detailArea)

local tabs = {"Propriedades", "Código", "Filhos"}
local tabBtns = {}
local activeTab = "Propriedades"

-- Conteúdo das abas
local propScroll = make("ScrollingFrame", {
    Size                  = UDim2.new(1,0,1,-36),
    Position              = UDim2.new(0,0,0,36),
    BackgroundTransparency = 1,
    BorderSizePixel       = 0,
    ScrollBarThickness    = 4,
    ScrollBarImageColor3  = ACCENT,
    CanvasSize            = UDim2.new(0,0,0,0),
    ZIndex                = 6,
    Visible               = true,
}, detailArea)
make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1)}, propScroll)

local codeBox = make("TextBox", {
    Size                  = UDim2.new(1,0,1,-36),
    Position              = UDim2.new(0,0,0,36),
    BackgroundColor3      = Color3.fromRGB(18,18,24),
    TextColor3            = GREEN,
    Font                  = Enum.Font.Code,
    TextSize              = 11,
    Text                  = "",
    ClearTextOnFocus      = false,
    MultiLine             = true,
    TextXAlignment        = Enum.TextXAlignment.Left,
    TextYAlignment        = Enum.TextYAlignment.Top,
    BorderSizePixel       = 0,
    ZIndex                = 6,
    Visible               = false,
    TextEditable          = false,
}, detailArea)
make("UIPadding", {PaddingLeft = UDim.new(0,6), PaddingTop = UDim.new(0,4)}, codeBox)

local childScroll = make("ScrollingFrame", {
    Size                  = UDim2.new(1,0,1,-36),
    Position              = UDim2.new(0,0,0,36),
    BackgroundTransparency = 1,
    BorderSizePixel       = 0,
    ScrollBarThickness    = 4,
    ScrollBarImageColor3  = ACCENT,
    CanvasSize            = UDim2.new(0,0,0,0),
    ZIndex                = 6,
    Visible               = false,
}, detailArea)
make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1)}, childScroll)

-- Botão "Copiar nome" no painel de detalhes
local copyNameBtn = make("TextButton", {
    Size            = UDim2.new(0,110,0,28),
    Position        = UDim2.new(1,-118,0,4),
    BackgroundColor3 = ACCENT,
    Text            = "⎘ Copiar Nome",
    TextColor3      = Color3.new(1,1,1),
    Font            = Enum.Font.Gotham,
    TextSize        = 11,
    BorderSizePixel = 0,
    ZIndex          = 7,
    Visible         = false,
}, tabBar)
make("UICorner", {CornerRadius = UDim.new(0,5)}, copyNameBtn)

-- Pop-up para fallback de cópia
local popup = make("Frame", {
    Size            = UDim2.new(0.8,0,0,80),
    Position        = UDim2.new(0.1,0,0.4,0),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex          = 20,
    Visible         = false,
}, screenGui)
make("UICorner", {CornerRadius = UDim.new(0,8)}, popup)
local popupLabel = make("TextLabel", {
    Size            = UDim2.new(1,-8,0.6,0),
    Position        = UDim2.new(0,4,0,4),
    BackgroundTransparency = 1,
    Text            = "",
    TextColor3      = TEXT,
    Font            = Enum.Font.Code,
    TextSize        = 11,
    TextWrapped     = true,
    TextXAlignment  = Enum.TextXAlignment.Left,
    ZIndex          = 21,
}, popup)
local popupClose = make("TextButton", {
    Size            = UDim2.new(1,0,0.4,-4),
    Position        = UDim2.new(0,0,0.6,0),
    BackgroundColor3 = ACCENT,
    Text            = "OK",
    TextColor3      = Color3.new(1,1,1),
    Font            = Enum.Font.GothamBold,
    TextSize        = 13,
    BorderSizePixel = 0,
    ZIndex          = 21,
}, popup)
make("UICorner", {CornerRadius = UDim.new(0,6)}, popupClose)

local function showPopup(text)
    popupLabel.Text = text
    popup.Visible = true
end
popupClose.MouseButton1Click:Connect(function() popup.Visible = false end)

-- ── Lógica de abas ───────────────────────────────────────────

local tabPanels = {Propriedades = propScroll, Código = codeBox, Filhos = childScroll}

local function switchTab(name)
    activeTab = name
    for _, panel in pairs(tabPanels) do panel.Visible = false end
    tabPanels[name].Visible = true
    for _, btn in ipairs(tabBtns) do
        btn.BackgroundColor3 = (btn.Name == name) and ACCENT or DARK
        btn.TextColor3       = (btn.Name == name) and Color3.new(1,1,1) or MUTED
    end
end

-- Cria os botões de abas
local tabW = 1 / #tabs
for i, tabName in ipairs(tabs) do
    local btn = make("TextButton", {
        Name            = tabName,
        Size            = UDim2.new(tabW - 0.01, 0, 1, -2),
        Position        = UDim2.new((i-1)*tabW, 2, 0, 1),
        BackgroundColor3 = (tabName == activeTab) and ACCENT or DARK,
        Text            = tabName,
        TextColor3      = (tabName == activeTab) and Color3.new(1,1,1) or MUTED,
        Font            = Enum.Font.Gotham,
        TextSize        = 11,
        BorderSizePixel = 0,
        ZIndex          = 7,
    }, tabBar)
    make("UICorner", {CornerRadius = UDim.new(0,5)}, btn)
    btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
    table.insert(tabBtns, btn)
end

-- ── Estado global ─────────────────────────────────────────────

local selectedInstance = nil
local expandedNodes    = {}  -- cache de nós expandidos: {[inst] = true}
local treeRows         = {}  -- lista de instâncias renderizadas na árvore

-- ── Limpa o painel de detalhes ────────────────────────────────

local function clearDetails()
    for _, c in ipairs(propScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    for _, c in ipairs(childScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    codeBox.Text = ""
    propScroll.CanvasSize  = UDim2.new(0,0,0,0)
    childScroll.CanvasSize = UDim2.new(0,0,0,0)
    copyNameBtn.Visible = false
end

-- ── Exibe propriedades da instância selecionada ───────────────

local function showProperties(inst)
    clearDetails()
    copyNameBtn.Visible = true

    -- Aba Propriedades
    local props = {"Name","ClassName","Parent","Archivable"}
    -- tenta GetProperties() se o executor expõe
    local ok, dynProps = pcall(function()
        return inst:GetProperties and inst:GetProperties() or {}
    end)
    if ok and dynProps then
        for k, _ in pairs(dynProps) do table.insert(props, k) end
    end

    local function addPropRow(key, val)
        local row = make("Frame", {
            Size            = UDim2.new(1,0,0,24),
            BackgroundColor3 = Color3.fromRGB(26,26,33),
            BorderSizePixel = 0,
            ZIndex          = 7,
        }, propScroll)
        make("TextLabel", {
            Size            = UDim2.new(0.45,0,1,0),
            BackgroundTransparency = 1,
            Text            = " " .. tostring(key),
            TextColor3      = MUTED,
            Font            = Enum.Font.Gotham,
            TextSize        = 11,
            TextXAlignment  = Enum.TextXAlignment.Left,
            ZIndex          = 8,
        }, row)
        make("TextLabel", {
            Size            = UDim2.new(0.55,0,1,0),
            Position        = UDim2.new(0.45,0,0,0),
            BackgroundTransparency = 1,
            Text            = tostring(val),
            TextColor3      = TEXT,
            Font            = Enum.Font.Code,
            TextSize        = 10,
            TextXAlignment  = Enum.TextXAlignment.Left,
            TextTruncate    = Enum.TextTruncate.AtEnd,
            ZIndex          = 8,
        }, row)
    end

    local seen = {}
    for _, key in ipairs(props) do
        if not seen[key] then
            seen[key] = true
            local ok2, val = pcall(function() return inst[key] end)
            addPropRow(key, ok2 and val or "⚠ protegido")
        end
    end
    -- Atualiza canvas
    propScroll.CanvasSize = UDim2.new(0, 0, 0, treeLayout.AbsoluteContentSize.Y)

    -- Aba Código (apenas para scripts)
    local isScript = inst:IsA("LuaSourceContainer")
    if isScript then
        local src = tryDecompile(inst)
        if src then
            codeBox.Text = src
        else
            codeBox.Text = "-- Script protegido: descompilação não disponível."
            codeBox.TextColor3 = RED
        end
    else
        codeBox.Text = "-- Não é um script."
        codeBox.TextColor3 = MUTED
    end

    -- Aba Filhos
    for _, c in ipairs(childScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local ok3, children = pcall(function() return inst:GetChildren() end)
    if ok3 then
        for _, child in ipairs(children) do
            local row = make("TextLabel", {
                Size            = UDim2.new(1,0,0,22),
                BackgroundTransparency = 1,
                Text            = "  " .. child.Name .. "  (" .. child.ClassName .. ")",
                TextColor3      = TEXT,
                Font            = Enum.Font.Code,
                TextSize        = 11,
                TextXAlignment  = Enum.TextXAlignment.Left,
                ZIndex          = 7,
            }, childScroll)
        end
        childScroll.CanvasSize = UDim2.new(0,0,0,#children*23)
    end
end

-- ── Renderização da árvore ────────────────────────────────────

local function clearTree()
    for _, c in ipairs(treeScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    treeRows = {}
end

-- Renderiza uma linha da árvore (recursivo)
local function renderNode(inst, depth)
    if not inst or not inst.Parent then return end

    local realName, _ = getRealName(inst)
    local hasChildren = #inst:GetChildren() > 0
    local isExpanded  = expandedNodes[inst]

    local rowH = 30
    local row = make("Frame", {
        Size            = UDim2.new(1, 0, 0, rowH),
        BackgroundColor3 = (selectedInstance == inst) and Color3.fromRGB(40,60,90) or DARK,
        BorderSizePixel = 0,
        ZIndex          = 6,
    }, treeScroll)

    -- Ícone expandir/recolher
    local arrow = make("TextButton", {
        Size            = UDim2.new(0, 20, 1, 0),
        Position        = UDim2.new(0, depth * INDENT, 0, 0),
        BackgroundTransparency = 1,
        Text            = hasChildren and (isExpanded and "▾" or "▸") or "·",
        TextColor3      = ACCENT,
        Font            = Enum.Font.GothamBold,
        TextSize        = 13,
        ZIndex          = 7,
    }, row)

    -- Label do nome
    local labelX = depth * INDENT + 22
    local label = make("TextButton", {
        Size            = UDim2.new(1, -labelX, 1, 0),
        Position        = UDim2.new(0, labelX, 0, 0),
        BackgroundTransparency = 1,
        Text            = realName .. "  " .. inst.ClassName,
        TextColor3      = TEXT,
        Font            = Enum.Font.Gotham,
        TextSize        = 12,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextTruncate    = Enum.TextTruncate.AtEnd,
        ZIndex          = 7,
    }, row)

    table.insert(treeRows, {row = row, inst = inst})

    -- Selecionar instância
    label.MouseButton1Click:Connect(function()
        selectedInstance = inst
        showProperties(inst)
        switchTab("Propriedades")
        -- Atualiza destaque (re-renderiza a árvore para atualizar cor)
        -- Apenas muda a cor da linha selecionada sem re-render completo
        for _, entry in ipairs(treeRows) do
            entry.row.BackgroundColor3 = (entry.inst == inst)
                and Color3.fromRGB(40,60,90) or DARK
        end
    end)

    -- Expandir/recolher
    arrow.MouseButton1Click:Connect(function()
        if hasChildren then
            expandedNodes[inst] = not expandedNodes[inst]
            -- Re-renderiza a árvore
            local scrollPos = treeScroll.CanvasPosition
            clearTree()
            for _, service in ipairs(game:GetChildren()) do
                renderNode(service, 0)
            end
            treeScroll.CanvasSize = UDim2.new(0,0,0,treeLayout.AbsoluteContentSize.Y)
            treeScroll.CanvasPosition = scrollPos
        end
    end)

    -- ── Toque longo: copiar filhos recursivos ────────────────
    local touchStart = 0
    local longPressThreshold = 0.6  -- segundos
    local longPressTriggered = false

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = tick()
            longPressTriggered = false
        end
    end)

    row.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if not longPressTriggered and (tick() - touchStart) >= longPressThreshold then
                longPressTriggered = true
                local lines = buildChildList(inst, 0)
                local text = table.concat(lines, "\n")
                if text == "" then text = "(sem filhos)" end
                local copied = copyText(text)
                if not copied then showPopup(text) end
            end
        end
    end)

    -- Renderiza filhos se expandido
    if isExpanded and hasChildren then
        local ok, children = pcall(function() return inst:GetChildren() end)
        if ok then
            for _, child in ipairs(children) do
                renderNode(child, depth + 1)
            end
        end
    end
end

-- Popula a árvore com todos os serviços do jogo
local function buildTree()
    clearTree()
    local services = game:GetChildren()
    for _, service in ipairs(services) do
        renderNode(service, 0)
    end
    treeScroll.CanvasSize = UDim2.new(0, 0, 0, treeLayout.AbsoluteContentSize.Y)
end

-- ── Botão copiar nome ─────────────────────────────────────────

copyNameBtn.MouseButton1Click:Connect(function()
    if not selectedInstance then return end
    local name, warned = getRealName(selectedInstance)
    local display = warned and ("[⚠ possível proteção] " .. name) or name
    local copied = copyText(name)
    if not copied then
        showPopup("Nome: " .. display)
    else
        copyNameBtn.Text = "✓ Copiado!"
        task.delay(1.5, function() copyNameBtn.Text = "⎘ Copiar Nome" end)
    end
end)

-- ── Toggle da GUI ─────────────────────────────────────────────

local isOpen = false

local function openGui()
    isOpen = true
    mainFrame.Visible = true
    toggleBtn.Visible = false
    buildTree()
end

local function closeGui()
    isOpen = false
    mainFrame.Visible = false
    toggleBtn.Visible = true
end

toggleBtn.MouseButton1Click:Connect(openGui)
closeBtn.MouseButton1Click:Connect(closeGui)
refreshBtn.MouseButton1Click:Connect(function()
    clearDetails()
    buildTree()
end)

-- ── Drag do botão flutuante ───────────────────────────────────

local dragging = false
local dragStart, startPos

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos  = toggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── Inicialização ─────────────────────────────────────────────

-- Script pronto. O botão flutuante fica visível ao injetar.
-- Toque no botão "DEX" para abrir o explorador.
print("[DexExplorer Mobile] Injetado com sucesso. Toque no botão DEX para abrir.")
