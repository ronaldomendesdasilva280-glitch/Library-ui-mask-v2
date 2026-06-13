-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          SAVE INSTANCES PRO  v3  ⚡ MAX POWER EDITION           ║
-- ║   Decompiler Cascade • Real Names • Fixed Progress • No Hang    ║
-- ╚══════════════════════════════════════════════════════════════════╝

local CoreGui    = game:GetService("CoreGui")
local UIS        = game:GetService("UserInputService")

-- ══════════════════════════════════════════════════════════════════
--  DETECÇÃO DE CAPACIDADES DO EXECUTOR
--  Testa cada API individualmente com pcall para não crashar
-- ══════════════════════════════════════════════════════════════════
local EXE = {
    writefile   = (typeof(writefile)   == "function"),
    makefolder  = (typeof(makefolder)  == "function"),
    isfile      = (typeof(isfile)      == "function"),
    isfolder    = (typeof(isfolder)    == "function"),
    -- Decompile APIs — testa cada uma
    decompile         = (typeof(decompile)         == "function"),
    decomp            = (typeof(decomp)            == "function"),  -- alias alguns executores
    getscriptbytecode = (typeof(getscriptbytecode) == "function"),
    dumpstring        = (typeof(dumpstring)        == "function"),  -- Synapse legado
}

-- ══════════════════════════════════════════════════════════════════
--  SISTEMA DE DECOMPILE EM CASCATA
--  Tenta todas as APIs conhecidas, da mais completa para fallback
-- ══════════════════════════════════════════════════════════════════
local function maxDecompile(scriptObj)
    local name = tostring(scriptObj.Name)
    local path = ""
    do
        local parts, cur = {}, scriptObj
        while cur and cur ~= game do
            table.insert(parts, 1, tostring(cur.Name))
            cur = cur.Parent
        end
        path = table.concat(parts, ".")
    end

    local header = string.format(
        "-- Script: %s\n-- Path:   %s\n-- Class:  %s\n%s\n",
        name, path, scriptObj.ClassName, string.rep("-", 60)
    )

    -- TENTATIVA 1: decompile() — padrão na maioria (Synapse X, Solara, Wave)
    if EXE.decompile then
        local ok, src = pcall(decompile, scriptObj)
        if ok and type(src) == "string" and #src > 10 then
            return header .. src
        end
    end

    -- TENTATIVA 2: decomp() — alias usado em alguns forks
    if EXE.decomp then
        local ok, src = pcall(decomp, scriptObj)
        if ok and type(src) == "string" and #src > 10 then
            return header .. "-- [via decomp()]\n" .. src
        end
    end

    -- TENTATIVA 3: dumpstring() — Synapse X legado / KRNL antigo
    if EXE.dumpstring then
        local ok2, bc = pcall(getscriptbytecode, scriptObj)
        if ok2 and type(bc) == "string" and #bc > 0 then
            local ok3, src = pcall(dumpstring, bc)
            if ok3 and type(src) == "string" and #src > 10 then
                return header .. "-- [via dumpstring()]\n" .. src
            end
        end
    end

    -- TENTATIVA 4: getscriptbytecode() puro — salva bytecode bruto
    -- Útil para análise manual mesmo sem decompile
    if EXE.getscriptbytecode then
        local ok, bc = pcall(getscriptbytecode, scriptObj)
        if ok and type(bc) == "string" and #bc > 0 then
            -- Converte para hex legível
            local hex = {}
            for i = 1, #bc do
                hex[i] = string.format("%02X", string.byte(bc, i))
            end
            return header
                .. "-- [decompile indisponível neste executor]\n"
                .. "-- Bytecode bruto em hex (pode usar unluac/luadec externamente):\n"
                .. "-- BYTECODE_HEX_START\n--[[\n"
                .. table.concat(hex, " ")
                .. "\n--]]\n-- BYTECODE_HEX_END\n"
        end
    end

    -- TENTATIVA 5: Script source via propriedade (funciona se não ofuscado)
    do
        local ok, src = pcall(function() return scriptObj.Source end)
        if ok and type(src) == "string" and #src > 10 then
            return header .. "-- [via .Source]\n" .. src
        end
    end

    -- FALLBACK FINAL: stub informativo
    return header
        .. "-- [Nenhuma API de decompile disponível neste executor]\n"
        .. "-- Execute em Synapse X, Solara ou Wave para melhores resultados.\n"
        .. string.format("-- ClassName: %s | Name: %s\n", scriptObj.ClassName, name)
end

-- ══════════════════════════════════════════════════════════════════
--  PASTAS DE SAÍDA
-- ══════════════════════════════════════════════════════════════════
local ROOT   = "SaveInstances_v3"
local F_SCR  = ROOT .. "/Scripts"
local F_LOC  = ROOT .. "/LocalScripts"
local F_MOD  = ROOT .. "/ModuleScripts"
local F_REM  = ROOT .. "/Remotes.txt"

-- Nome REAL do script — sem alterar nenhum caractere válido
-- Remove apenas o que o sistema de arquivos não aceita
local function realName(obj)
    local n = tostring(obj.Name)
    -- Remove apenas: \ / : * ? " < > | e nulos
    n = n:gsub('[\\/:*?"<>|\0]', "_")
    if #n == 0 then n = "_unnamed" end
    return n
end

-- Nomes duplicados: adiciona sufixo numérico preservando o nome real
local function uniqueName(registry, base, ext)
    local key = base .. ext
    if not registry[key] then
        registry[key] = 1
        return base .. ext
    else
        registry[key] = registry[key] + 1
        return base .. "_" .. registry[key] .. ext
    end
end

local function mkdirs()
    if not EXE.makefolder then return end
    for _, d in ipairs({ ROOT, F_SCR, F_LOC, F_MOD }) do
        pcall(makefolder, d)
    end
end

local function safeWrite(path, content)
    if not EXE.writefile then return end
    local ok, err = pcall(writefile, path, tostring(content))
    if not ok then
        -- tenta nome fallback se falhar (caractere raro no nome)
        local fallback = path:gsub("[^%w%./_ %-]", "_")
        pcall(writefile, fallback, tostring(content))
    end
end

local function fullPath(obj)
    local parts, cur = {}, obj
    while cur and cur ~= game do
        table.insert(parts, 1, tostring(cur.Name))
        cur = cur.Parent
    end
    return table.concat(parts, " > ")
end

-- ══════════════════════════════════════════════════════════════════
--  CLASSES IGNORADAS (partes visuais/físicas do jogo)
-- ══════════════════════════════════════════════════════════════════
local SKIP = {}
for _, v in ipairs({
    "Part","MeshPart","UnionOperation","SpecialMesh","Model",
    "Decal","Texture","SurfaceAppearance","SelectionBox",
    "Humanoid","HumanoidDescription","Accessory","Shirt","Pants",
    "CharacterMesh","BodyColors","Hat","Tool","BasePart",
    "WedgePart","TrussPart","CylinderMesh","BlockMesh",
    "CornerWedgePart","Seat","VehicleSeat","SpawnLocation",
    "Terrain","Sky","Atmosphere","Lighting","Beam","Trail",
    "ParticleEmitter","Fire","Smoke","Sparkles",
    "BillboardGui","SurfaceGui","Attachment",
    "Motor6D","Weld","WeldConstraint",
    "BallSocketConstraint","HingeConstraint",
    "BodyPosition","BodyVelocity","BodyGyro","BodyAngularVelocity",
    "ClickDetector","ProximityPrompt",
    "Sound","SoundGroup","SoundEffect","EqualizerSoundEffect",
    "Folder","Animation","AnimationController","Animator",
    "IntValue","StringValue","BoolValue","NumberValue",
    "ObjectValue","Vector3Value","CFrameValue","Color3Value","RayValue",
    "ForceField","SelectionPartLasso","SelectionPointLasso",
    "LocalizationTable","RemoteDebugger",
}) do SKIP[v] = true end

-- ══════════════════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════════════════
if CoreGui:FindFirstChild("SIP_v3") then
    CoreGui:FindFirstChild("SIP_v3"):Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name, sg.ResetOnSpawn, sg.DisplayOrder, sg.ZIndexBehavior =
    "SIP_v3", false, 999, Enum.ZIndexBehavior.Sibling
sg.Parent = CoreGui

-- Janela principal
local win = Instance.new("Frame", sg)
win.Name                = "MainWindow"
win.Size                = UDim2.new(0, 430, 0, 510)
win.Position            = UDim2.new(0.5,-215, 0.5,-255)
win.BackgroundColor3    = Color3.fromRGB(7, 5, 16)
win.BorderSizePixel     = 0
win.ClipsDescendants    = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color, winStroke.Thickness = Color3.fromRGB(90, 45, 230), 2

local winGrad = Instance.new("UIGradient", win)
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(13, 7, 30)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(9, 5, 22)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(5, 3, 12)),
})
winGrad.Rotation = 130

-- Header
local hdr = Instance.new("Frame", win)
hdr.Size             = UDim2.new(1, 0, 0, 66)
hdr.BackgroundColor3 = Color3.fromRGB(14, 7, 38)
hdr.BorderSizePixel  = 0
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 14)
local hGrad = Instance.new("UIGradient", hdr)
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 28, 195)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 48, 250)),
})
hGrad.Rotation = 90

-- Ícone + títulos
local function mkLabel(parent, props)
    local l = Instance.new("TextLabel", parent)
    for k, v in pairs(props) do l[k] = v end
    l.BackgroundTransparency = 1
    return l
end

mkLabel(hdr, {
    Text="⚡", TextSize=26, Font=Enum.Font.GothamBold,
    Size=UDim2.new(0,32,1,0), Position=UDim2.new(0,14,0,0),
    TextColor3=Color3.fromRGB(255,220,60),
    TextYAlignment=Enum.TextYAlignment.Center,
})
mkLabel(hdr, {
    Text="SAVE INSTANCES  v3  MAX", TextSize=15,
    Font=Enum.Font.GothamBold,
    Size=UDim2.new(1,-160,0,24), Position=UDim2.new(0,52,0,10),
    TextColor3=Color3.new(1,1,1),
    TextXAlignment=Enum.TextXAlignment.Left,
})
mkLabel(hdr, {
    Text="Cascade Decompiler  •  Real Names  •  No Hang",
    TextSize=10, Font=Enum.Font.Gotham,
    Size=UDim2.new(1,-160,0,18), Position=UDim2.new(0,52,0,34),
    TextColor3=Color3.fromRGB(175,135,255),
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- Badge versão
local vbadge = Instance.new("TextLabel", hdr)
vbadge.Size = UDim2.new(0,46,0,20)
vbadge.Position = UDim2.new(1,-116,0.5,-10)
vbadge.BackgroundColor3 = Color3.fromRGB(255,185,0)
vbadge.Text = "v3 MAX"
vbadge.TextColor3 = Color3.fromRGB(25,15,0)
vbadge.TextSize = 10
vbadge.Font = Enum.Font.GothamBold
vbadge.BorderSizePixel = 0
Instance.new("UICorner", vbadge).CornerRadius = UDim.new(0, 6)

-- Botão fechar
local xbtn = Instance.new("TextButton", hdr)
xbtn.Size = UDim2.new(0,30,0,30)
xbtn.Position = UDim2.new(1,-42,0.5,-15)
xbtn.BackgroundColor3 = Color3.fromRGB(185,32,65)
xbtn.Text = "✕"; xbtn.TextColor3 = Color3.new(1,1,1)
xbtn.TextSize = 13; xbtn.Font = Enum.Font.GothamBold
xbtn.BorderSizePixel = 0; xbtn.AutoButtonColor = false
Instance.new("UICorner", xbtn).CornerRadius = UDim.new(0, 8)
xbtn.MouseButton1Click:Connect(function() sg:Destroy() end)
xbtn.MouseEnter:Connect(function() xbtn.BackgroundColor3 = Color3.fromRGB(230,50,80) end)
xbtn.MouseLeave:Connect(function() xbtn.BackgroundColor3 = Color3.fromRGB(185,32,65) end)

-- Drag
do
    local drag, di, ds, sp
    hdr.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    hdr.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or
           i.UserInputType == Enum.UserInputType.Touch then di = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == di and drag then
            local d = i.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                     sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

-- ── Cards de contagem (grid 2x2) ──────────────────────────────
local cardVals = {}
local cardData = {
    { "📜", "Scripts",       Color3.fromRGB(140, 80, 255)  },
    { "📋", "LocalScripts",  Color3.fromRGB(70, 155, 255)  },
    { "🧩", "ModuleScripts", Color3.fromRGB(205, 95, 255)  },
    { "📡", "Remotes",       Color3.fromRGB(50, 215, 175)  },
}
for i, d in ipairs(cardData) do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local c = Instance.new("Frame", win)
    c.Size             = UDim2.new(0.5, col == 0 and -16 or -16, 0, 42)
    c.Position         = UDim2.new(col * 0.5, col == 0 and 10 or 6, 0, 76 + row * 50)
    c.BackgroundColor3 = Color3.fromRGB(14, 9, 34)
    c.BorderSizePixel  = 0
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke", c)
    cs.Color, cs.Thickness = d[3], 1

    local ic = Instance.new("TextLabel", c)
    ic.Size=UDim2.new(0,26,1,0); ic.Position=UDim2.new(0,8,0,0)
    ic.BackgroundTransparency=1; ic.Text=d[1]
    ic.TextSize=16; ic.Font=Enum.Font.Gotham

    local nm = Instance.new("TextLabel", c)
    nm.Size=UDim2.new(1,-38,0,16); nm.Position=UDim2.new(0,36,0,4)
    nm.BackgroundTransparency=1; nm.Text=d[2]
    nm.TextColor3=Color3.fromRGB(165,145,215)
    nm.TextSize=10; nm.Font=Enum.Font.Gotham
    nm.TextXAlignment=Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", c)
    vl.Size=UDim2.new(1,-38,0,18); vl.Position=UDim2.new(0,36,0,22)
    vl.BackgroundTransparency=1; vl.Text="—"
    vl.TextColor3=d[3]; vl.TextSize=15; vl.Font=Enum.Font.GothamBold
    vl.TextXAlignment=Enum.TextXAlignment.Left
    cardVals[i] = vl
end

-- ── Barra de progresso (com label de fase) ────────────────────
local phaseLabel = Instance.new("TextLabel", win)
phaseLabel.Size = UDim2.new(1,-20,0,16)
phaseLabel.Position = UDim2.new(0,10,0,180)
phaseLabel.BackgroundTransparency = 1
phaseLabel.Text = "Aguardando..."
phaseLabel.TextColor3 = Color3.fromRGB(170,140,230)
phaseLabel.TextSize = 11; phaseLabel.Font = Enum.Font.Gotham
phaseLabel.TextXAlignment = Enum.TextXAlignment.Left

local pbg = Instance.new("Frame", win)
pbg.Size=UDim2.new(1,-20,0,22); pbg.Position=UDim2.new(0,10,0,198)
pbg.BackgroundColor3=Color3.fromRGB(14,9,34)
pbg.BorderSizePixel=0; pbg.ClipsDescendants=true
Instance.new("UICorner",pbg).CornerRadius=UDim.new(0,10)

local pbar = Instance.new("Frame", pbg)
pbar.Size=UDim2.new(0,0,1,0)
pbar.BackgroundColor3=Color3.fromRGB(90,45,220)
pbar.BorderSizePixel=0
Instance.new("UICorner",pbar).CornerRadius=UDim.new(0,10)
local pbGrad = Instance.new("UIGradient", pbar)
pbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(90,45,220)),
    ColorSequenceKeypoint.new(0.45,Color3.fromRGB(155,65,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(55,185,255)),
})

local pctLbl = Instance.new("TextLabel", pbg)
pctLbl.Size=UDim2.new(1,0,1,0)
pctLbl.BackgroundTransparency=1
pctLbl.Text="0%"; pctLbl.TextColor3=Color3.new(1,1,1)
pctLbl.TextSize=12; pctLbl.Font=Enum.Font.GothamBold

-- ── Status + Speed ────────────────────────────────────────────
local stLbl = Instance.new("TextLabel", win)
stLbl.Size=UDim2.new(1,-20,0,16); stLbl.Position=UDim2.new(0,10,0,224)
stLbl.BackgroundTransparency=1; stLbl.Text="Pronto. Clique em INICIAR."
stLbl.TextColor3=Color3.fromRGB(140,115,200)
stLbl.TextSize=11; stLbl.Font=Enum.Font.Gotham
stLbl.TextXAlignment=Enum.TextXAlignment.Left

local spdLbl = Instance.new("TextLabel", win)
spdLbl.Size=UDim2.new(1,-20,0,14); spdLbl.Position=UDim2.new(0,10,0,242)
spdLbl.BackgroundTransparency=1; spdLbl.Text=""
spdLbl.TextColor3=Color3.fromRGB(70,200,130)
spdLbl.TextSize=11; spdLbl.Font=Enum.Font.Code
spdLbl.TextXAlignment=Enum.TextXAlignment.Left

-- ── Log box ───────────────────────────────────────────────────
local logF = Instance.new("ScrollingFrame", win)
logF.Size=UDim2.new(1,-20,0,100); logF.Position=UDim2.new(0,10,0,260)
logF.BackgroundColor3=Color3.fromRGB(5,3,12)
logF.BorderSizePixel=0; logF.ScrollBarThickness=3
logF.ScrollBarImageColor3=Color3.fromRGB(65,28,155)
logF.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UICorner",logF).CornerRadius=UDim.new(0,8)
local logLL = Instance.new("UIListLayout",logF)
logLL.SortOrder=Enum.SortOrder.LayoutOrder; logLL.Padding=UDim.new(0,1)
local logN = 0

local function addLog(msg, col)
    logN = logN + 1
    local l = Instance.new("TextLabel", logF)
    l.Size=UDim2.new(1,-6,0,15); l.BackgroundTransparency=1
    l.Text="> "..tostring(msg)
    l.TextColor3=col or Color3.fromRGB(135,205,165)
    l.TextSize=11; l.Font=Enum.Font.Code
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.LayoutOrder=logN
    logF.CanvasSize=UDim2.new(0,0,0,logLL.AbsoluteContentSize.Y+8)
    logF.CanvasPosition=Vector2.new(0,math.huge)
end

-- ── Botão principal ───────────────────────────────────────────
local btn = Instance.new("TextButton", win)
btn.Size=UDim2.new(1,-20,0,46); btn.Position=UDim2.new(0,10,0,368)
btn.BackgroundColor3=Color3.fromRGB(78,32,205)
btn.Text="⚡  INICIAR SAVE  ⚡"
btn.TextColor3=Color3.new(1,1,1)
btn.TextSize=15; btn.Font=Enum.Font.GothamBold
btn.BorderSizePixel=0; btn.AutoButtonColor=false
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,12)
local bGrad=Instance.new("UIGradient",btn)
bGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(98,42,235)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(45,145,255)),
})
bGrad.Rotation=90
local bStroke=Instance.new("UIStroke",btn)
bStroke.Color=Color3.fromRGB(125,65,255); bStroke.Thickness=1.5

-- Info executor
local exeLbl = Instance.new("TextLabel", win)
exeLbl.Size=UDim2.new(1,-20,0,30); exeLbl.Position=UDim2.new(0,10,0,420)
exeLbl.BackgroundTransparency=1
exeLbl.TextColor3=Color3.fromRGB(100,80,150)
exeLbl.TextSize=10; exeLbl.Font=Enum.Font.Code
exeLbl.TextXAlignment=Enum.TextXAlignment.Left
exeLbl.TextWrapped=true
exeLbl.Text=string.format(
    "Executor: write=%s  decompile=%s  dumpstring=%s  bytecode=%s",
    EXE.writefile and "✓" or "✗",
    EXE.decompile and "✓" or "✗",
    EXE.dumpstring and "✓" or "✗",
    EXE.getscriptbytecode and "✓" or "✗"
)

-- ══════════════════════════════════════════════════════════════════
--  HELPERS DE UI
-- ══════════════════════════════════════════════════════════════════
local function setProgress(p)
    p = math.clamp(p, 0, 100)
    pbar.Size = UDim2.new(p / 100, 0, 1, 0)
    pctLbl.Text = string.format("%.1f%%", p)
end

local function setStatus(s)  stLbl.Text = tostring(s)  end
local function setPhase(s)   phaseLabel.Text = tostring(s)  end
local function setSpeed(s)   spdLbl.Text = tostring(s)  end

-- ══════════════════════════════════════════════════════════════════
--  SAVE PRINCIPAL
-- ══════════════════════════════════════════════════════════════════
local saving = false

local function doSave()
    if saving then return end
    saving = true

    btn.Text = "⏳  Processando..."
    btn.BackgroundColor3 = Color3.fromRGB(35,35,60)
    setProgress(0)
    setStatus("Iniciando...")
    setPhase("Fase 1/5 — Varredura")
    addLog("=== SAVE INSTANCES v3 MAX INICIADO ===", Color3.fromRGB(255,215,55))
    task.wait(0.05)

    -- ── FASE 1: Varredura completa (O(n) — 1 passagem) ──────────
    local t0 = os.clock()
    local scripts, locals, modules, remotes = {}, {}, {}, {}
    local RC = {
        RemoteEvent=true, RemoteFunction=true,
        UnreliableRemoteEvent=true,
        BindableEvent=true, BindableFunction=true,
    }

    local ok, desc = pcall(function() return game:GetDescendants() end)
    if not ok then
        addLog("ERRO: GetDescendants falhou!", Color3.fromRGB(255,60,60))
        saving = false
        return
    end

    for _, obj in ipairs(desc) do
        local c = obj.ClassName
        if not SKIP[c] then
            if     c == "Script"       then scripts[#scripts+1] = obj
            elseif c == "LocalScript"  then locals[#locals+1]   = obj
            elseif c == "ModuleScript" then modules[#modules+1] = obj
            elseif RC[c]               then remotes[#remotes+1] = obj
            end
        end
    end

    local scanMs = math.floor((os.clock() - t0) * 1000)
    addLog(string.format("Varredura: %dms | SCR=%d LOC=%d MOD=%d REM=%d",
        scanMs, #scripts, #locals, #modules, #remotes),
        Color3.fromRGB(90,215,255))

    cardVals[1].Text = tostring(#scripts)
    cardVals[2].Text = tostring(#locals)
    cardVals[3].Text = tostring(#modules)
    cardVals[4].Text = tostring(#remotes)

    setProgress(5)
    task.wait(0.02)

    -- ── FASE 2: Criar pastas ─────────────────────────────────────
    setPhase("Fase 2/5 — Criando pastas")
    mkdirs()
    setProgress(8)
    addLog("Pastas criadas: " .. ROOT, Color3.fromRGB(160,160,255))
    task.wait(0.02)

    -- ── CONTADOR DE PROGRESSO CORRETO ────────────────────────────
    -- Total real de itens que vão ser processados
    local TOTAL = #scripts + #locals + #modules + 1  -- +1 = remotes.txt
    local DONE  = 0
    local tSave = os.clock()

    -- Progresso vai de 8% até 97% durante o save
    local function tick(label)
        DONE = DONE + 1
        local pct = 8 + (DONE / TOTAL) * 89
        setProgress(pct)
        local elapsed = os.clock() - tSave
        local rate = elapsed > 0 and (DONE / elapsed) or 0
        setSpeed(string.format("%.0f items/s  |  %d/%d  |  %.1fs", rate, DONE, TOTAL, elapsed))
        setStatus(label)
        -- Yield apenas a cada 10 items para não travar mas manter UI fluída
        if DONE % 10 == 0 then
            task.wait()
        end
    end

    -- ── FASE 3: Scripts ──────────────────────────────────────────
    setPhase("Fase 3/5 — Scripts (" .. #scripts .. ")")
    addLog("Salvando Scripts...", Color3.fromRGB(175,135,255))
    local regS = {}
    for _, s in ipairs(scripts) do
        local base  = realName(s)
        local fname = uniqueName(regS, base, ".lua")
        local src   = maxDecompile(s)
        safeWrite(F_SCR .. "/" .. fname, src)
        tick("📜 " .. s.Name)
    end
    addLog("Scripts: OK (" .. #scripts .. ")", Color3.fromRGB(100,255,150))

    -- ── FASE 4: LocalScripts ─────────────────────────────────────
    setPhase("Fase 4a/5 — LocalScripts (" .. #locals .. ")")
    addLog("Salvando LocalScripts...", Color3.fromRGB(125,175,255))
    local regL = {}
    for _, s in ipairs(locals) do
        local base  = realName(s)
        local fname = uniqueName(regL, base, ".lua")
        local src   = maxDecompile(s)
        safeWrite(F_LOC .. "/" .. fname, src)
        tick("📋 " .. s.Name)
    end
    addLog("LocalScripts: OK (" .. #locals .. ")", Color3.fromRGB(100,255,150))

    -- ── FASE 4b: ModuleScripts ───────────────────────────────────
    setPhase("Fase 4b/5 — ModuleScripts (" .. #modules .. ")")
    addLog("Salvando ModuleScripts...", Color3.fromRGB(200,115,255))
    local regM = {}
    for _, s in ipairs(modules) do
        local base  = realName(s)
        local fname = uniqueName(regM, base, ".lua")
        local src   = maxDecompile(s)
        safeWrite(F_MOD .. "/" .. fname, src)
        tick("🧩 " .. s.Name)
    end
    addLog("ModuleScripts: OK (" .. #modules .. ")", Color3.fromRGB(100,255,150))

    -- ── FASE 5: Remotes.txt (tudo em memória → 1 write) ─────────
    setPhase("Fase 5/5 — Remotes.txt")
    addLog("Compilando Remotes.txt...", Color3.fromRGB(50,210,170))
    do
        local groups = {
            RemoteEvent={}, RemoteFunction={},
            UnreliableRemoteEvent={},
            BindableEvent={}, BindableFunction={},
        }
        local order = {
            "RemoteEvent","RemoteFunction",
            "UnreliableRemoteEvent","BindableEvent","BindableFunction",
        }
        for _, r in ipairs(remotes) do
            local g = groups[r.ClassName]
            if g then g[#g+1] = r end
        end

        local buf = {
            "╔══════════════════════════════════════════════════════════════╗",
            "║          SAVE INSTANCES v3 MAX — Remotes.txt                ║",
            string.format("║  Gerado: %-51s║", os.date("%d/%m/%Y  %H:%M:%S")),
            string.format("║  Total:  %-51s║", #remotes .. " remote(s) encontrados"),
            "╚══════════════════════════════════════════════════════════════╝",
            "",
        }
        for _, typeName in ipairs(order) do
            local g = groups[typeName]
            if g and #g > 0 then
                buf[#buf+1] = string.format("▶  %s  (%d)", typeName, #g)
                buf[#buf+1] = string.rep("─", 56)
                for idx, r in ipairs(g) do
                    buf[#buf+1] = string.format("  [%d]  %s", idx, r.Name)
                    buf[#buf+1] = string.format("       Path  : %s", fullPath(r))
                    buf[#buf+1] = string.format("       Class : %s", r.ClassName)
                    buf[#buf+1] = ""
                end
                buf[#buf+1] = ""
            end
        end
        safeWrite(F_REM, table.concat(buf, "\n"))
        tick("📡 Remotes.txt")
    end
    addLog("Remotes.txt: OK (" .. #remotes .. ")", Color3.fromRGB(100,255,150))

    -- ── FINALIZAÇÃO ──────────────────────────────────────────────
    local elapsed = os.clock() - tSave
    setProgress(100)
    setPhase("✅ Concluído!")
    setStatus(string.format("Salvo em %.1fs  |  pasta: %s", elapsed, ROOT))
    setSpeed(string.format("Média: %.0f items/s  |  Total: %d arquivos",
        TOTAL / math.max(elapsed, 0.1),
        #scripts + #locals + #modules + #remotes
    ))

    addLog("══════════════════════════════", Color3.fromRGB(90,200,255))
    addLog(string.format("✅ CONCLUÍDO em %.2fs", elapsed), Color3.fromRGB(55,250,115))
    addLog("Scripts:       " .. #scripts,  Color3.fromRGB(185,255,185))
    addLog("LocalScripts:  " .. #locals,   Color3.fromRGB(185,255,185))
    addLog("ModuleScripts: " .. #modules,  Color3.fromRGB(185,255,185))
    addLog("Remotes:       " .. #remotes,  Color3.fromRGB(185,255,185))
    addLog("Pasta: " .. ROOT, Color3.fromRGB(255,215,55))

    btn.Text = "✅  SAVE CONCLUÍDO"
    btn.BackgroundColor3 = Color3.fromRGB(22,135,65)

    task.delay(5, function()
        if sg and sg.Parent then
            btn.Text = "⚡  INICIAR SAVE  ⚡"
            btn.BackgroundColor3 = Color3.fromRGB(78,32,205)
            saving = false
        end
    end)
end

-- Hover do botão
btn.MouseEnter:Connect(function()
    if not saving then btn.BackgroundColor3 = Color3.fromRGB(98,48,245) end
end)
btn.MouseLeave:Connect(function()
    if not saving then btn.BackgroundColor3 = Color3.fromRGB(78,32,205) end
end)
btn.MouseButton1Click:Connect(function()
    task.spawn(doSave)
end)

-- ── Logs iniciais ─────────────────────────────────────────────
if not EXE.writefile then
    addLog("⚠ writefile ausente — sem gravação real", Color3.fromRGB(255,165,45))
end
if EXE.decompile then
    addLog("✓ decompile() detectado", Color3.fromRGB(55,230,110))
elseif EXE.dumpstring and EXE.getscriptbytecode then
    addLog("✓ dumpstring+bytecode detectado", Color3.fromRGB(55,230,110))
elseif EXE.getscriptbytecode then
    addLog("⚠ Só bytecode — sem decompile completo", Color3.fromRGB(255,200,55))
else
    addLog("✗ Nenhuma API de decompile encontrada", Color3.fromRGB(255,75,75))
end
addLog("GUI v3 pronta. Clique em INICIAR SAVE.", Color3.fromRGB(135,165,255))
