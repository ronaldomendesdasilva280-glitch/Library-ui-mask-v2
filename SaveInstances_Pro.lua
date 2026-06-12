-- ╔══════════════════════════════════════════════════════════════╗
-- ║           SAVE INSTANCES PRO - by Script Generator          ║
-- ║     Salva: Scripts, LocalScripts, ModuleScripts, Remotes    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Serviços ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local CoreGui        = game:GetService("CoreGui")
local HttpService    = game:GetService("HttpService")

-- ── Verificações de executor ───────────────────────────────────
local canWriteFile   = (writefile  ~= nil)
local canDecompile   = (decompile  ~= nil)
local canGetSrc      = (getscriptbytecode ~= nil or getscripthash ~= nil)

-- ── Configurações ──────────────────────────────────────────────
local FOLDER_ROOT    = "SaveInstances_Pro"
local FOLDER_SCRIPTS = FOLDER_ROOT .. "/Scripts"
local FOLDER_LOCAL   = FOLDER_ROOT .. "/LocalScripts"
local FOLDER_MODULE  = FOLDER_ROOT .. "/ModuleScripts"
local FILE_REMOTES   = FOLDER_ROOT .. "/Remotes.txt"

-- ── Classes que NÃO devem ser salvas (partes visuais do jogo) ──
local SKIP_CLASSES = {
    Part              = true, MeshPart          = true, UnionOperation    = true,
    SpecialMesh       = true, Model             = true, Decal             = true,
    Texture           = true, SurfaceAppearance = true, SelectionBox      = true,
    Humanoid          = true, HumanoidDescription = true, Accessory       = true,
    Shirt             = true, Pants             = true, CharacterMesh     = true,
    BodyColors        = true, Hat               = true, Tool              = true,
    BasePart          = true, WedgePart         = true, TrussPart         = true,
    CylinderMesh      = true, BlockMesh         = true, CornerWedgePart   = true,
    Seat              = true, VehicleSeat       = true, SpawnLocation     = true,
    Terrain           = true, Sky               = true, Atmosphere        = true,
    Lighting          = true, Beam              = true, Trail             = true,
    ParticleEmitter   = true, Fire              = true, Smoke             = true,
    Sparkles          = true, BillboardGui      = true, SurfaceGui        = true,
    Attachment        = true, Motor6D           = true, Weld              = true,
    WeldConstraint    = true, BallSocketConstraint = true, HingeConstraint = true,
    BodyPosition      = true, BodyVelocity      = true, BodyGyro          = true,
    ClickDetector     = true, ProximityPrompt   = true, Sound             = true,
    SoundGroup        = true, Folder            = true, Animation         = true,
    AnimationController = true, Animator        = true, IntValue          = true,
    StringValue       = true, BoolValue         = true, NumberValue       = true,
    ObjectValue       = true, Vector3Value      = true, CFrameValue       = true,
    Color3Value       = true, RayValue          = true,
}

-- ══════════════════════════════════════════════════════════════
--                        GUI BUILDER
-- ══════════════════════════════════════════════════════════════

-- Remove instância anterior se existir
if CoreGui:FindFirstChild("SaveInstancesPro") then
    CoreGui:FindFirstChild("SaveInstancesPro"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "SaveInstancesPro"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 999
ScreenGui.Parent           = CoreGui

-- ── Janela principal ───────────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Name              = "MainFrame"
MainFrame.Size              = UDim2.new(0, 400, 0, 480)
MainFrame.Position          = UDim2.new(0.5, -200, 0.5, -240)
MainFrame.BackgroundColor3  = Color3.fromRGB(10, 10, 20)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui

-- Borda brilhante
local MainBorder = Instance.new("UIStroke")
MainBorder.Color            = Color3.fromRGB(100, 60, 255)
MainBorder.Thickness        = 2
MainBorder.Parent           = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius     = UDim.new(0, 14)
MainCorner.Parent           = MainFrame

-- Gradiente de fundo
local MainGrad = Instance.new("UIGradient")
MainGrad.Color              = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(12, 8, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 10, 45)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(8, 6, 20)),
})
MainGrad.Rotation           = 135
MainGrad.Parent             = MainFrame

-- ── Topo / Header ──────────────────────────────────────────────
local Header = Instance.new("Frame")
Header.Size                 = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3     = Color3.fromRGB(18, 10, 50)
Header.BorderSizePixel      = 0
Header.Parent               = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius   = UDim.new(0, 14)
HeaderCorner.Parent         = Header

local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color            = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 40, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 60, 255)),
})
HeaderGrad.Rotation         = 90
HeaderGrad.Parent           = Header

-- Ícone
local IconLabel = Instance.new("TextLabel")
IconLabel.Size              = UDim2.new(0, 40, 0, 40)
IconLabel.Position          = UDim2.new(0, 15, 0.5, -20)
IconLabel.BackgroundTransparency = 1
IconLabel.Text              = "💾"
IconLabel.TextSize          = 28
IconLabel.Font              = Enum.Font.GothamBold
IconLabel.Parent            = Header

-- Título
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size             = UDim2.new(1, -120, 0, 26)
TitleLabel.Position         = UDim2.new(0, 60, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text             = "SAVE INSTANCES PRO"
TitleLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize         = 17
TitleLabel.Font             = Enum.Font.GothamBold
TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
TitleLabel.Parent           = Header

-- Subtítulo
local SubLabel = Instance.new("TextLabel")
SubLabel.Size               = UDim2.new(1, -120, 0, 18)
SubLabel.Position           = UDim2.new(0, 60, 0, 38)
SubLabel.BackgroundTransparency = 1
SubLabel.Text               = "Scripts • Modules • Remotes"
SubLabel.TextColor3         = Color3.fromRGB(180, 140, 255)
SubLabel.TextSize           = 11
SubLabel.Font               = Enum.Font.Gotham
SubLabel.TextXAlignment     = Enum.TextXAlignment.Left
SubLabel.Parent             = Header

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size               = UDim2.new(0, 32, 0, 32)
CloseBtn.Position           = UDim2.new(1, -44, 0.5, -16)
CloseBtn.BackgroundColor3   = Color3.fromRGB(200, 40, 80)
CloseBtn.Text               = "✕"
CloseBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize           = 14
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.BorderSizePixel    = 0
CloseBtn.Parent             = Header

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 8)
CloseBtnCorner.Parent       = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ── Cards de status ────────────────────────────────────────────
local function makeCard(parent, posY, icon, label, valDefault)
    local card = Instance.new("Frame")
    card.Size               = UDim2.new(1, -30, 0, 44)
    card.Position           = UDim2.new(0, 15, 0, posY)
    card.BackgroundColor3   = Color3.fromRGB(20, 14, 50)
    card.BorderSizePixel    = 0
    card.Parent             = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius         = UDim.new(0, 10)
    cc.Parent               = card

    local cs = Instance.new("UIStroke")
    cs.Color                = Color3.fromRGB(60, 30, 140)
    cs.Thickness            = 1
    cs.Parent               = card

    local ic = Instance.new("TextLabel")
    ic.Size                 = UDim2.new(0, 30, 1, 0)
    ic.Position             = UDim2.new(0, 10, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text                 = icon
    ic.TextSize             = 18
    ic.Font                 = Enum.Font.Gotham
    ic.Parent               = card

    local lb = Instance.new("TextLabel")
    lb.Size                 = UDim2.new(0, 180, 1, 0)
    lb.Position             = UDim2.new(0, 44, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text                 = label
    lb.TextColor3           = Color3.fromRGB(200, 180, 255)
    lb.TextSize             = 12
    lb.Font                 = Enum.Font.Gotham
    lb.TextXAlignment       = Enum.TextXAlignment.Left
    lb.Parent               = card

    local vl = Instance.new("TextLabel")
    vl.Name                 = "Value"
    vl.Size                 = UDim2.new(0, 80, 1, 0)
    vl.Position             = UDim2.new(1, -88, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text                 = valDefault
    vl.TextColor3           = Color3.fromRGB(120, 220, 140)
    vl.TextSize             = 13
    vl.Font                 = Enum.Font.GothamBold
    vl.TextXAlignment       = Enum.TextXAlignment.Right
    vl.Parent               = card

    return vl
end

local cardScripts   = makeCard(MainFrame, 85,  "📜", "Scripts encontrados",      "—")
local cardLocal     = makeCard(MainFrame, 136, "📋", "LocalScripts encontrados",  "—")
local cardModule    = makeCard(MainFrame, 187, "🧩", "ModuleScripts encontrados", "—")
local cardRemotes   = makeCard(MainFrame, 238, "📡", "Remotes encontrados",       "—")

-- ── Barra de loading ───────────────────────────────────────────
local LoadBG = Instance.new("Frame")
LoadBG.Size                 = UDim2.new(1, -30, 0, 26)
LoadBG.Position             = UDim2.new(0, 15, 0, 295)
LoadBG.BackgroundColor3     = Color3.fromRGB(20, 14, 50)
LoadBG.BorderSizePixel      = 0
LoadBG.ClipsDescendants     = true
LoadBG.Parent               = MainFrame

local LoadBGCorner = Instance.new("UICorner")
LoadBGCorner.CornerRadius   = UDim.new(0, 10)
LoadBGCorner.Parent         = LoadBG

local LoadBar = Instance.new("Frame")
LoadBar.Size                = UDim2.new(0, 0, 1, 0)
LoadBar.BackgroundColor3    = Color3.fromRGB(100, 60, 255)
LoadBar.BorderSizePixel     = 0
LoadBar.Parent              = LoadBG

local LoadBarCorner = Instance.new("UICorner")
LoadBarCorner.CornerRadius  = UDim.new(0, 10)
LoadBarCorner.Parent        = LoadBar

local LoadBarGrad = Instance.new("UIGradient")
LoadBarGrad.Color           = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(100, 60, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 80, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 200, 255)),
})
LoadBarGrad.Parent          = LoadBar

local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size           = UDim2.new(1, 0, 1, 0)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text           = "0%"
PercentLabel.TextColor3     = Color3.fromRGB(255, 255, 255)
PercentLabel.TextSize       = 12
PercentLabel.Font           = Enum.Font.GothamBold
PercentLabel.Parent         = LoadBG

-- ── Label de status ────────────────────────────────────────────
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size            = UDim2.new(1, -30, 0, 22)
StatusLabel.Position        = UDim2.new(0, 15, 0, 326)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text            = "Pronto para salvar."
StatusLabel.TextColor3      = Color3.fromRGB(160, 130, 220)
StatusLabel.TextSize        = 11
StatusLabel.Font            = Enum.Font.Gotham
StatusLabel.Parent          = MainFrame

-- ── Log box ────────────────────────────────────────────────────
local LogBox = Instance.new("ScrollingFrame")
LogBox.Size                 = UDim2.new(1, -30, 0, 80)
LogBox.Position             = UDim2.new(0, 15, 0, 352)
LogBox.BackgroundColor3     = Color3.fromRGB(8, 5, 18)
LogBox.BorderSizePixel      = 0
LogBox.ScrollBarThickness   = 4
LogBox.ScrollBarImageColor3 = Color3.fromRGB(80, 40, 180)
LogBox.CanvasSize           = UDim2.new(0, 0, 0, 0)
LogBox.Parent               = MainFrame

local LogBoxCorner = Instance.new("UICorner")
LogBoxCorner.CornerRadius   = UDim.new(0, 10)
LogBoxCorner.Parent         = LogBox

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder         = Enum.SortOrder.LayoutOrder
LogLayout.Padding           = UDim.new(0, 2)
LogLayout.Parent            = LogBox

local logLineCount = 0
local function addLog(msg, color)
    color = color or Color3.fromRGB(150, 220, 180)
    logLineCount += 1
    local line = Instance.new("TextLabel")
    line.Size               = UDim2.new(1, -8, 0, 16)
    line.BackgroundTransparency = 1
    line.Text               = "> " .. msg
    line.TextColor3         = color
    line.TextSize           = 11
    line.Font               = Enum.Font.Code
    line.TextXAlignment     = Enum.TextXAlignment.Left
    line.LayoutOrder        = logLineCount
    line.Parent             = LogBox
    LogBox.CanvasSize       = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y + 10)
    LogBox.CanvasPosition   = Vector2.new(0, LogBox.CanvasSize.Y.Offset)
end

-- ── Botão salvar ───────────────────────────────────────────────
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                = UDim2.new(1, -30, 0, 44)
SaveBtn.Position            = UDim2.new(0, 15, 0, 424)
SaveBtn.BackgroundColor3    = Color3.fromRGB(90, 40, 220)
SaveBtn.Text                = "⚡  INICIAR SAVE"
SaveBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize            = 15
SaveBtn.Font                = Enum.Font.GothamBold
SaveBtn.BorderSizePixel     = 0
SaveBtn.AutoButtonColor     = false
SaveBtn.Parent              = MainFrame

local SaveBtnCorner = Instance.new("UICorner")
SaveBtnCorner.CornerRadius  = UDim.new(0, 12)
SaveBtnCorner.Parent        = SaveBtn

local SaveBtnGrad = Instance.new("UIGradient")
SaveBtnGrad.Color           = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 240)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 255)),
})
SaveBtnGrad.Rotation        = 90
SaveBtnGrad.Parent          = SaveBtn

local SaveBtnStroke = Instance.new("UIStroke")
SaveBtnStroke.Color         = Color3.fromRGB(140, 80, 255)
SaveBtnStroke.Thickness     = 1.5
SaveBtnStroke.Parent        = SaveBtn

-- ── Arrastar janela ────────────────────────────────────────────
do
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--                     FUNÇÕES AUXILIARES
-- ══════════════════════════════════════════════════════════════

local function setProgress(pct)
    pct = math.clamp(pct, 0, 100)
    LoadBar.Size            = UDim2.new(pct / 100, 0, 1, 0)
    PercentLabel.Text       = math.floor(pct) .. "%"
end

local function setStatus(msg)
    StatusLabel.Text = msg
end

local function sanitizeName(name)
    -- Remove caracteres inválidos para nome de arquivo
    return name:gsub('[\\/:*?"<>|]', "_")
end

local function getFullPath(obj)
    local path = {}
    local cur  = obj
    while cur and cur ~= game do
        table.insert(path, 1, sanitizeName(cur.Name))
        cur = cur.Parent
    end
    return table.concat(path, "/")
end

local function tryDecompile(script)
    if canDecompile then
        local ok, src = pcall(decompile, script)
        if ok and src and #src > 0 then
            return src
        end
    end
    -- Fallback: bytecode comment
    if canGetSrc then
        local ok2, bc = pcall(getscriptbytecode, script)
        if ok2 and bc then
            return "-- [Decompile indisponível neste executor]\n-- Bytecode capturado mas não decodificado.\n-- Script: " .. getFullPath(script)
        end
    end
    return "-- [Sem permissão de decompile neste executor]\n-- Script: " .. getFullPath(script)
end

local function safeWrite(path, content)
    if canWriteFile then
        local ok, err = pcall(writefile, path, content)
        if not ok then
            addLog("ERRO ao escrever: " .. tostring(err), Color3.fromRGB(255, 80, 80))
        end
    end
end

local function ensureFolder(path)
    if canWriteFile and makefolder then
        pcall(makefolder, path)
    end
end

-- ══════════════════════════════════════════════════════════════
--                     LÓGICA DE SAVE
-- ══════════════════════════════════════════════════════════════

local isSaving = false

local function doSave()
    if isSaving then return end
    isSaving = true

    SaveBtn.Text            = "⏳  Salvando..."
    SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)

    addLog("Iniciando varredura...", Color3.fromRGB(100, 200, 255))
    setProgress(0)
    setStatus("Criando estrutura de pastas...")
    task.wait(0.05)

    -- Criar pastas
    ensureFolder(FOLDER_ROOT)
    ensureFolder(FOLDER_SCRIPTS)
    ensureFolder(FOLDER_LOCAL)
    ensureFolder(FOLDER_MODULE)

    -- Listas para coleta
    local scripts_list  = {}
    local locals_list   = {}
    local modules_list  = {}
    local remotes_list  = {}

    setStatus("Varrendo o jogo...")
    addLog("Varrendo instâncias...", Color3.fromRGB(180, 180, 255))

    -- ── Varredura completa ─────────────────────────────────────
    local function scanDescendants(root)
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if not ok then return end

        for _, obj in ipairs(descendants) do
            local cls = obj.ClassName

            -- Scripts
            if cls == "Script" then
                table.insert(scripts_list, obj)
            elseif cls == "LocalScript" then
                table.insert(locals_list, obj)
            elseif cls == "ModuleScript" then
                table.insert(modules_list, obj)

            -- Remotes (todos os tipos)
            elseif cls == "RemoteEvent"
                or cls == "RemoteFunction"
                or cls == "UnreliableRemoteEvent"
                or cls == "BindableEvent"
                or cls == "BindableFunction" then
                table.insert(remotes_list, obj)
            end
            -- Tudo que estiver em SKIP_CLASSES é simplesmente ignorado
        end
    end

    scanDescendants(game)

    -- Atualiza cards de contagem
    cardScripts.Text  = tostring(#scripts_list)
    cardLocal.Text    = tostring(#locals_list)
    cardModule.Text   = tostring(#modules_list)
    cardRemotes.Text  = tostring(#remotes_list)

    addLog("Scripts: "  .. #scripts_list, Color3.fromRGB(120, 255, 160))
    addLog("LocalScripts: " .. #locals_list, Color3.fromRGB(120, 255, 160))
    addLog("Modules: "  .. #modules_list, Color3.fromRGB(120, 255, 160))
    addLog("Remotes: "  .. #remotes_list, Color3.fromRGB(120, 255, 160))
    task.wait(0.05)

    local totalItems = #scripts_list + #locals_list + #modules_list + 1 -- +1 para o arquivo remotes
    local doneItems  = 0

    local function tickProgress(label)
        doneItems += 1
        local pct = (doneItems / totalItems) * 100
        setProgress(pct)
        setStatus(label)
        task.wait() -- yield para não travar
    end

    -- ── Salvar Scripts ─────────────────────────────────────────
    addLog("Salvando Scripts...", Color3.fromRGB(200, 160, 255))
    for _, s in ipairs(scripts_list) do
        local src  = tryDecompile(s)
        local name = sanitizeName(s.Name)
        local path = FOLDER_SCRIPTS .. "/" .. name .. ".lua"
        safeWrite(path, src)
        tickProgress("Script: " .. s.Name)
    end

    -- ── Salvar LocalScripts ────────────────────────────────────
    addLog("Salvando LocalScripts...", Color3.fromRGB(200, 160, 255))
    for _, s in ipairs(locals_list) do
        local src  = tryDecompile(s)
        local name = sanitizeName(s.Name)
        local path = FOLDER_LOCAL .. "/" .. name .. ".lua"
        safeWrite(path, src)
        tickProgress("LocalScript: " .. s.Name)
    end

    -- ── Salvar ModuleScripts ───────────────────────────────────
    addLog("Salvando ModuleScripts...", Color3.fromRGB(200, 160, 255))
    for _, s in ipairs(modules_list) do
        local src  = tryDecompile(s)
        local name = sanitizeName(s.Name)
        local path = FOLDER_MODULE .. "/" .. name .. ".lua"
        safeWrite(path, src)
        tickProgress("Module: " .. s.Name)
    end

    -- ── Salvar Remotes em TXT único ────────────────────────────
    addLog("Salvando Remotes...", Color3.fromRGB(100, 200, 255))
    do
        local lines = {
            "╔══════════════════════════════════════════════════════════════╗",
            "║                 SAVE INSTANCES PRO — Remotes                ║",
            "║         Gerado em: " .. os.date("%d/%m/%Y %H:%M:%S") .. "              ║",
            "╚══════════════════════════════════════════════════════════════╝",
            "",
            string.format("Total de Remotes encontrados: %d", #remotes_list),
            "",
            string.rep("─", 64),
            "",
        }

        -- Agrupar por tipo
        local groups = {
            RemoteEvent           = {},
            RemoteFunction        = {},
            UnreliableRemoteEvent = {},
            BindableEvent         = {},
            BindableFunction      = {},
        }
        for _, r in ipairs(remotes_list) do
            local g = groups[r.ClassName]
            if g then table.insert(g, r) end
        end

        local typeOrder = {
            "RemoteEvent", "RemoteFunction",
            "UnreliableRemoteEvent",
            "BindableEvent", "BindableFunction"
        }
        for _, typeName in ipairs(typeOrder) do
            local group = groups[typeName]
            if group and #group > 0 then
                table.insert(lines, "▶ " .. typeName .. " (" .. #group .. ")")
                table.insert(lines, string.rep("─", 40))
                for _, r in ipairs(group) do
                    local fullPath = getFullPath(r)
                    table.insert(lines, "  • " .. r.Name)
                    table.insert(lines, "    Path : " .. fullPath)
                    table.insert(lines, "")
                end
                table.insert(lines, "")
            end
        end

        safeWrite(FILE_REMOTES, table.concat(lines, "\n"))
        tickProgress("Remotes.txt salvo!")
    end

    -- ── Finalização ────────────────────────────────────────────
    setProgress(100)
    setStatus("✅ Concluído! Pasta: " .. FOLDER_ROOT)

    addLog("══════════════════════════════", Color3.fromRGB(100, 200, 255))
    addLog("SAVE COMPLETO!", Color3.fromRGB(80, 255, 140))
    addLog("Pasta: " .. FOLDER_ROOT, Color3.fromRGB(200, 255, 200))
    addLog("Scripts:  " .. #scripts_list, Color3.fromRGB(200, 255, 200))
    addLog("Locals:   " .. #locals_list, Color3.fromRGB(200, 255, 200))
    addLog("Modules:  " .. #modules_list, Color3.fromRGB(200, 255, 200))
    addLog("Remotes:  " .. #remotes_list, Color3.fromRGB(200, 255, 200))

    SaveBtn.Text              = "✅  SAVE COMPLETO"
    SaveBtn.BackgroundColor3  = Color3.fromRGB(30, 160, 80)

    -- Sparkle no botão
    task.delay(3, function()
        SaveBtn.Text             = "⚡  INICIAR SAVE"
        SaveBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 220)
        isSaving                 = false
    end)
end

-- ── Hover do botão ─────────────────────────────────────────────
SaveBtn.MouseEnter:Connect(function()
    if not isSaving then
        SaveBtn.BackgroundColor3 = Color3.fromRGB(110, 60, 255)
    end
end)
SaveBtn.MouseLeave:Connect(function()
    if not isSaving then
        SaveBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 220)
    end
end)
SaveBtn.MouseButton1Click:Connect(function()
    task.spawn(doSave)
end)

-- ── Aviso se writefile não disponível ──────────────────────────
if not canWriteFile then
    addLog("AVISO: writefile não disponível!", Color3.fromRGB(255, 180, 60))
    addLog("Uso em executor limitado.", Color3.fromRGB(255, 180, 60))
    setStatus("⚠️ Executor sem writefile — modo visualização")
end

addLog("GUI carregada. Clique em INICIAR SAVE.", Color3.fromRGB(140, 180, 255))
