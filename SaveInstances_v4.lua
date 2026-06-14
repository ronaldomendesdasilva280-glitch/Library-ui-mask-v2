-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        SAVE INSTANCES PRO  v4  ⚡ ULTIMATE EDITION              ║
-- ║  Filter • ReadableOnly • AutoMax • SelfDecomp • Cascade Decomp  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local CoreGui = game:GetService("CoreGui")
local UIS     = game:GetService("UserInputService")
local RS      = game:GetService("RunService")

-- ══════════════════════════════════════════════════════════════════
--  DETECÇÃO DE CAPACIDADES DO EXECUTOR
-- ══════════════════════════════════════════════════════════════════
local EXE = {
    writefile         = typeof(writefile)         == "function",
    makefolder        = typeof(makefolder)        == "function",
    decompile         = typeof(decompile)         == "function",
    decomp            = typeof(decomp)            == "function",
    getscriptbytecode = typeof(getscriptbytecode) == "function",
    dumpstring        = typeof(dumpstring)        == "function",
    getthreadidentity = typeof(getthreadidentity) == "function",
    setthreadidentity = typeof(setthreadidentity) == "function",
    getgc             = typeof(getgc)             == "function",
    getrenv           = typeof(getrenv)           == "function",
    getloadedmodules  = typeof(getloadedmodules)  == "function",
}

-- ══════════════════════════════════════════════════════════════════
--  CONFIGURAÇÕES / TOGGLES  (modificados pela GUI)
-- ══════════════════════════════════════════════════════════════════
local CFG = {
    filterEnabled   = false,   -- Salvar só nomes que batem com o filtro
    filterNames     = {},      -- Tabela de nomes/termos do filtro
    readableOnly    = false,   -- Salvar só scripts realmente descompilados
    autoMax         = false,   -- Usar 100% do poder do executor
    selfDecomp      = false,   -- Descompile interno sem depender do executor
}

-- ══════════════════════════════════════════════════════════════════
--  PASTAS DE SAÍDA
-- ══════════════════════════════════════════════════════════════════
local ROOT  = "SaveInstances_v4"
local F_SCR = ROOT .. "/Scripts"
local F_LOC = ROOT .. "/LocalScripts"
local F_MOD = ROOT .. "/ModuleScripts"
local F_REM = ROOT .. "/Remotes.txt"

-- ══════════════════════════════════════════════════════════════════
--  CLASSES IGNORADAS
-- ══════════════════════════════════════════════════════════════════
local SKIP = {}
for _,v in ipairs({
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
    "ForceField",
}) do SKIP[v] = true end

-- ══════════════════════════════════════════════════════════════════
--  SISTEMA DE FILTRO POR NOME
--  Verifica se o nome do script bate com algum termo da lista
--  Match: nome exato OU contém 3 letras consecutivas do termo
-- ══════════════════════════════════════════════════════════════════
local function passesFilter(scriptName)
    if not CFG.filterEnabled or #CFG.filterNames == 0 then
        return true -- sem filtro = passa tudo
    end
    local lname = string.lower(scriptName)
    for _, term in ipairs(CFG.filterNames) do
        local lterm = string.lower(term)
        -- Match exato
        if lname == lterm then return true end
        -- Nome contém o termo
        if lname:find(lterm, 1, true) then return true end
        -- Termo contém o nome
        if lterm:find(lname, 1, true) then return true end
        -- Match parcial: verifica se pelo menos 3 letras consecutivas do termo aparecem no nome
        if #lterm >= 3 then
            for i = 1, #lterm - 2 do
                local tri = lterm:sub(i, i + 2)
                if lname:find(tri, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════
--  DETECTOR DE LEGIBILIDADE
--  Verifica se o resultado do decompile é código Lua real
-- ══════════════════════════════════════════════════════════════════
local LUA_KEYWORDS = {
    "local ","function ","end","return","if ","then","else",
    "for ","while ","do","repeat","until","not ","and ","or ",
    "true","false","nil","in ","pairs","ipairs","require",
    "game:","workspace","script","print(","warn(",
}
local function isReadable(src)
    if type(src) ~= "string" or #src < 15 then return false end
    -- Rejeita se parecer bytecode puro (começa com \27Lua)
    if src:sub(1,1) == "\27" then return false end
    -- Rejeita se mais de 30% dos chars forem não-printáveis
    local nonprint = 0
    for i = 1, math.min(#src, 300) do
        local b = src:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
            nonprint = nonprint + 1
        end
    end
    if nonprint / math.min(#src, 300) > 0.3 then return false end
    -- Verifica presença de pelo menos 2 keywords Lua
    local hits = 0
    for _, kw in ipairs(LUA_KEYWORDS) do
        if src:find(kw, 1, true) then
            hits = hits + 1
            if hits >= 2 then return true end
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════
--  SELF-DECOMPILER INTERNO
--  Várias técnicas independentes do executor
-- ══════════════════════════════════════════════════════════════════
local function selfDecompile(scriptObj)
    -- TÉCNICA 1: .Source direto (scripts não-protegidos)
    do
        local ok, src = pcall(function() return scriptObj.Source end)
        if ok and type(src)=="string" and isReadable(src) then
            return "-- [SelfDecomp: .Source]\n" .. src
        end
    end

    -- TÉCNICA 2: Procurar no GC pelo closure do script
    if EXE.getgc then
        local ok, gc = pcall(getgc, true)
        if ok and gc then
            for _, v in ipairs(gc) do
                if type(v) == "function" then
                    local ok2, info = pcall(function()
                        return debug and debug.getinfo and debug.getinfo(v, "S")
                    end)
                    if ok2 and info and info.source then
                        local src = tostring(info.source)
                        if src:find(scriptObj.Name, 1, true) and isReadable(src) then
                            return "-- [SelfDecomp: GC closure]\n" .. src
                        end
                    end
                end
            end
        end
    end

    -- TÉCNICA 3: getloadedmodules (ModuleScripts carregados)
    if EXE.getloadedmodules and scriptObj.ClassName == "ModuleScript" then
        local ok, mods = pcall(getloadedmodules)
        if ok and mods then
            for _, m in ipairs(mods) do
                if m == scriptObj then
                    local ok2, src = pcall(function() return m.Source end)
                    if ok2 and type(src)=="string" and isReadable(src) then
                        return "-- [SelfDecomp: loadedmodule]\n" .. src
                    end
                end
            end
        end
    end

    -- TÉCNICA 4: getrenv (ambiente do script — extrai upvalues)
    if EXE.getrenv then
        local ok, renv = pcall(getrenv)
        if ok and renv then
            local buf = {"-- [SelfDecomp: getrenv upvalues]\n-- Variáveis detectadas no ambiente:\n"}
            local count = 0
            for k, v in pairs(renv) do
                if type(k)=="string" and not k:match("^_") then
                    local tv = type(v)
                    if tv=="function" or tv=="table" or tv=="string" then
                        buf[#buf+1] = string.format("-- %s = (%s)", k, tv)
                        count = count + 1
                    end
                end
                if count > 80 then break end
            end
            if count > 0 then
                return table.concat(buf,"\n")
            end
        end
    end

    -- TÉCNICA 5: Elevação de identidade + decompile forçado
    if EXE.setthreadidentity and EXE.decompile then
        local prevId = 3
        if EXE.getthreadidentity then
            pcall(function() prevId = getthreadidentity() end)
        end
        pcall(setthreadidentity, 8) -- máxima permissão
        local ok, src = pcall(decompile, scriptObj)
        pcall(setthreadidentity, prevId)
        if ok and type(src)=="string" and isReadable(src) then
            return "-- [SelfDecomp: identity 8 + decompile]\n" .. src
        end
    end

    -- TÉCNICA 6: Leitura via bytecode + análise de strings
    if EXE.getscriptbytecode then
        local ok, bc = pcall(getscriptbytecode, scriptObj)
        if ok and type(bc)=="string" and #bc > 0 then
            -- Extrai strings legíveis embutidas no bytecode
            local strings = {}
            local cur = ""
            for i=1,#bc do
                local b = bc:byte(i)
                if b >= 32 and b < 127 then
                    cur = cur .. string.char(b)
                else
                    if #cur >= 4 then
                        strings[#strings+1] = cur
                    end
                    cur = ""
                end
            end
            if #cur >= 4 then strings[#strings+1] = cur end

            if #strings > 0 then
                local buf = {
                    "-- [SelfDecomp: string extraction do bytecode]",
                    "-- Strings legíveis encontradas no bytecode:",
                    "-- (Use unluac/luadec para decompile completo)",
                    "",
                }
                for i, s in ipairs(strings) do
                    if i > 200 then buf[#buf+1]="-- ... (truncado)"; break end
                    buf[#buf+1] = "-- " .. s
                end
                return table.concat(buf, "\n")
            end
        end
    end

    return nil -- falhou em todas as técnicas
end

-- ══════════════════════════════════════════════════════════════════
--  AUTO-MAX: Usa 100% das APIs do executor em sequência agressiva
-- ══════════════════════════════════════════════════════════════════
local function autoMaxDecompile(scriptObj)
    -- Eleva identidade ao máximo antes de tentar
    if EXE.setthreadidentity then
        pcall(setthreadidentity, 8)
    end

    -- Tenta todas as APIs disponíveis, guarda o MELHOR resultado
    local results = {}

    if EXE.decompile then
        local ok,src = pcall(decompile, scriptObj)
        if ok and type(src)=="string" and #src>10 then
            results[#results+1] = { score=#src, src="-- [autoMax: decompile]\n"..src }
        end
    end
    if EXE.decomp then
        local ok,src = pcall(decomp, scriptObj)
        if ok and type(src)=="string" and #src>10 then
            results[#results+1] = { score=#src, src="-- [autoMax: decomp]\n"..src }
        end
    end
    if EXE.getscriptbytecode and EXE.dumpstring then
        local ok,bc = pcall(getscriptbytecode, scriptObj)
        if ok and type(bc)=="string" then
            local ok2,src = pcall(dumpstring, bc)
            if ok2 and type(src)=="string" and #src>10 then
                results[#results+1] = { score=#src, src="-- [autoMax: dumpstring]\n"..src }
            end
        end
    end

    -- Decompile com tentativa de context switching
    if EXE.decompile and EXE.setthreadidentity then
        for _, id in ipairs({8, 7, 6}) do
            pcall(setthreadidentity, id)
            local ok,src = pcall(decompile, scriptObj)
            if ok and type(src)=="string" and #src>10 then
                results[#results+1] = { score=#src*1.1, src=string.format("-- [autoMax: identity %d]\n",id)..src }
            end
        end
    end

    -- Restaura identidade
    if EXE.setthreadidentity then
        pcall(setthreadidentity, 3)
    end

    -- Escolhe o resultado com maior conteúdo (mais completo)
    if #results > 0 then
        table.sort(results, function(a,b) return a.score > b.score end)
        return results[1].src
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
--  DECOMPILE PRINCIPAL — cascata com todos os sistemas
-- ══════════════════════════════════════════════════════════════════
local function fullDecompile(scriptObj)
    local name = tostring(scriptObj.Name)
    local parts, cur = {}, scriptObj
    while cur and cur~=game do table.insert(parts,1,tostring(cur.Name)); cur=cur.Parent end
    local path = table.concat(parts,".")

    local header = string.format(
        "-- ┌─────────────────────────────────────────────────┐\n"..
        "-- │ Script : %-38s│\n"..
        "-- │ Path   : %-38s│\n"..
        "-- │ Class  : %-38s│\n"..
        "-- └─────────────────────────────────────────────────┘\n",
        name:sub(1,38), path:sub(1,38), scriptObj.ClassName
    )

    local src = nil

    -- SISTEMA AUTO-MAX (tenta primeiro se ativo)
    if CFG.autoMax then
        src = autoMaxDecompile(scriptObj)
        if src and (not CFG.readableOnly or isReadable(src)) then
            return header .. src, true
        end
    end

    -- CASCATA PADRÃO
    -- 1) decompile()
    if not src and EXE.decompile then
        local ok,s = pcall(decompile, scriptObj)
        if ok and type(s)=="string" and #s>10 then src = s end
    end
    -- 2) decomp()
    if not src and EXE.decomp then
        local ok,s = pcall(decomp, scriptObj)
        if ok and type(s)=="string" and #s>10 then src = s end
    end
    -- 3) dumpstring + bytecode
    if not src and EXE.dumpstring and EXE.getscriptbytecode then
        local ok,bc = pcall(getscriptbytecode, scriptObj)
        if ok and type(bc)=="string" then
            local ok2,s = pcall(dumpstring, bc)
            if ok2 and type(s)=="string" and #s>10 then src = s end
        end
    end
    -- 4) .Source
    if not src then
        local ok,s = pcall(function() return scriptObj.Source end)
        if ok and type(s)=="string" and #s>10 then src = s end
    end

    -- SELF-DECOMP (se ativo e cascata falhou ou resultado ilegível)
    if CFG.selfDecomp and (not src or (CFG.readableOnly and not isReadable(src))) then
        local sd = selfDecompile(scriptObj)
        if sd and (not CFG.readableOnly or isReadable(sd)) then
            src = sd
        end
    end

    if not src then
        -- ReadableOnly: descarta
        if CFG.readableOnly then
            return nil, false
        end
        -- Fallback bytecode hex
        if EXE.getscriptbytecode then
            local ok,bc = pcall(getscriptbytecode, scriptObj)
            if ok and type(bc)=="string" and #bc>0 then
                local hex={}
                for i=1,math.min(#bc,2048) do
                    hex[i]=string.format("%02X",bc:byte(i))
                end
                src = "-- [bytecode raw — use unluac externamente]\n--[[\n"
                    ..table.concat(hex," ").."\n--]]\n"
                return header..src, false
            end
        end
        return header.."-- [nenhum método funcionou neste executor]\n", false
    end

    -- Verifica legibilidade se ReadableOnly ativo
    if CFG.readableOnly and not isReadable(src) then
        return nil, false -- descarta
    end

    return header .. src, true
end

-- ══════════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════════
local function realName(obj)
    local n = tostring(obj.Name):gsub('[\\/:*?"<>|\0]',"_")
    return #n>0 and n or "_unnamed"
end

local function uniqueName(reg, base, ext)
    local key = base..ext
    if not reg[key] then reg[key]=1; return key
    else reg[key]=reg[key]+1; return base.."_"..reg[key]..ext end
end

local function mkdirs()
    if not EXE.makefolder then return end
    for _,d in ipairs({ROOT,F_SCR,F_LOC,F_MOD}) do pcall(makefolder,d) end
end

local function safeWrite(path,content)
    if not EXE.writefile then return end
    if not pcall(writefile,path,tostring(content)) then
        pcall(writefile, path:gsub("[^%w%./_ %-]","_"), tostring(content))
    end
end

local function fullPath(obj)
    local p,c={},obj
    while c and c~=game do table.insert(p,1,tostring(c.Name)); c=c.Parent end
    return table.concat(p," > ")
end

-- ══════════════════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════════════════
if CoreGui:FindFirstChild("SIP_v4") then CoreGui:FindFirstChild("SIP_v4"):Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name,sg.ResetOnSpawn,sg.DisplayOrder,sg.ZIndexBehavior =
    "SIP_v4",false,999,Enum.ZIndexBehavior.Sibling
sg.Parent = CoreGui

-- ── Janela principal ──────────────────────────────────────────
local win = Instance.new("Frame",sg)
win.Name = "MainWin"
win.Size = UDim2.new(0,450,0,620)
win.Position = UDim2.new(0.5,-225,0.5,-310)
win.BackgroundColor3 = Color3.fromRGB(7,5,16)
win.BorderSizePixel = 0
win.ClipsDescendants = true
Instance.new("UICorner",win).CornerRadius = UDim.new(0,14)
local wStroke = Instance.new("UIStroke",win)
wStroke.Color,wStroke.Thickness = Color3.fromRGB(85,42,225),2
local wGrad = Instance.new("UIGradient",win)
wGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(13,7,30)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(5,3,12)),
})
wGrad.Rotation = 130

-- ── Header ────────────────────────────────────────────────────
local hdr = Instance.new("Frame",win)
hdr.Size = UDim2.new(1,0,0,64)
hdr.BackgroundColor3 = Color3.fromRGB(13,7,36)
hdr.BorderSizePixel = 0
Instance.new("UICorner",hdr).CornerRadius = UDim.new(0,14)
local hGrad = Instance.new("UIGradient",hdr)
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(62,26,190)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(122,46,245)),
})
hGrad.Rotation = 90

local function mkLbl(parent,props)
    local l=Instance.new("TextLabel",parent)
    for k,v in pairs(props) do l[k]=v end
    l.BackgroundTransparency=1
    return l
end

mkLbl(hdr,{Text="⚡",TextSize=24,Font=Enum.Font.GothamBold,
    Size=UDim2.new(0,30,1,0),Position=UDim2.new(0,13,0,0),
    TextColor3=Color3.fromRGB(255,215,50),
    TextYAlignment=Enum.TextYAlignment.Center})
mkLbl(hdr,{Text="SAVE INSTANCES  v4  ULTIMATE",TextSize=15,
    Font=Enum.Font.GothamBold,
    Size=UDim2.new(1,-155,0,22),Position=UDim2.new(0,48,0,9),
    TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left})
mkLbl(hdr,{Text="Filter • ReadableOnly • AutoMax • SelfDecomp",
    TextSize=10,Font=Enum.Font.Gotham,
    Size=UDim2.new(1,-155,0,16),Position=UDim2.new(0,48,0,32),
    TextColor3=Color3.fromRGB(170,130,255),TextXAlignment=Enum.TextXAlignment.Left})

local vb=Instance.new("TextLabel",hdr)
vb.Size=UDim2.new(0,52,0,20);vb.Position=UDim2.new(1,-118,0.5,-10)
vb.BackgroundColor3=Color3.fromRGB(255,180,0);vb.Text="v4 ULTRA"
vb.TextColor3=Color3.fromRGB(20,12,0);vb.TextSize=10
vb.Font=Enum.Font.GothamBold;vb.BorderSizePixel=0
Instance.new("UICorner",vb).CornerRadius=UDim.new(0,6)

local xb=Instance.new("TextButton",hdr)
xb.Size=UDim2.new(0,28,0,28);xb.Position=UDim2.new(1,-40,0.5,-14)
xb.BackgroundColor3=Color3.fromRGB(180,30,62);xb.Text="✕"
xb.TextColor3=Color3.new(1,1,1);xb.TextSize=12
xb.Font=Enum.Font.GothamBold;xb.BorderSizePixel=0;xb.AutoButtonColor=false
Instance.new("UICorner",xb).CornerRadius=UDim.new(0,8)
xb.MouseButton1Click:Connect(function() sg:Destroy() end)
xb.MouseEnter:Connect(function() xb.BackgroundColor3=Color3.fromRGB(225,48,78) end)
xb.MouseLeave:Connect(function() xb.BackgroundColor3=Color3.fromRGB(180,30,62) end)

-- Drag
do
    local drag,di,ds,sp
    hdr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or
           i.UserInputType==Enum.UserInputType.Touch then
            drag=true;ds=i.Position;sp=win.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    hdr.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or
           i.UserInputType==Enum.UserInputType.Touch then di=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==di and drag then
            local d=i.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ── Cards de stat (2x2) ───────────────────────────────────────
local cardVals={}
local cardD={
    {"📜","Scripts",      Color3.fromRGB(135,78,255)},
    {"📋","LocalScripts", Color3.fromRGB(68,152,255)},
    {"🧩","Modules",      Color3.fromRGB(202,92,255)},
    {"📡","Remotes",      Color3.fromRGB(48,210,172)},
}
for i,d in ipairs(cardD) do
    local col=(i-1)%2; local row=math.floor((i-1)/2)
    local c=Instance.new("Frame",win)
    c.Size=UDim2.new(0.5,-14,0,40)
    c.Position=UDim2.new(col*0.5,col==0 and 9 or 5,0,72+row*46)
    c.BackgroundColor3=Color3.fromRGB(13,8,32);c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,10)
    local cs=Instance.new("UIStroke",c);cs.Color,cs.Thickness=d[3],1
    local ic=Instance.new("TextLabel",c)
    ic.Size=UDim2.new(0,24,1,0);ic.Position=UDim2.new(0,7,0,0)
    ic.BackgroundTransparency=1;ic.Text=d[1];ic.TextSize=15;ic.Font=Enum.Font.Gotham
    local nm=Instance.new("TextLabel",c)
    nm.Size=UDim2.new(1,-34,0,15);nm.Position=UDim2.new(0,33,0,3)
    nm.BackgroundTransparency=1;nm.Text=d[2]
    nm.TextColor3=Color3.fromRGB(162,142,210);nm.TextSize=10;nm.Font=Enum.Font.Gotham
    nm.TextXAlignment=Enum.TextXAlignment.Left
    local vl=Instance.new("TextLabel",c)
    vl.Size=UDim2.new(1,-34,0,18);vl.Position=UDim2.new(0,33,0,20)
    vl.BackgroundTransparency=1;vl.Text="—"
    vl.TextColor3=d[3];vl.TextSize=14;vl.Font=Enum.Font.GothamBold
    vl.TextXAlignment=Enum.TextXAlignment.Left
    cardVals[i]=vl
end

-- ══════════════════════════════════════════════════════════════════
--  TOGGLES — builder genérico
-- ══════════════════════════════════════════════════════════════════
local TOGGLE_Y_START = 168
local toggleRefs = {}  -- guarda referências para atualizar visual

local function makeToggle(parent, posY, key, icon, title, desc, color, onToggle)
    local frame = Instance.new("Frame",parent)
    frame.Size = UDim2.new(1,-18,0,48)
    frame.Position = UDim2.new(0,9,0,posY)
    frame.BackgroundColor3 = Color3.fromRGB(12,7,28)
    frame.BorderSizePixel = 0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local fs=Instance.new("UIStroke",frame);fs.Color=Color3.fromRGB(35,20,80);fs.Thickness=1

    -- Ícone
    local ic=Instance.new("TextLabel",frame)
    ic.Size=UDim2.new(0,28,0,28);ic.Position=UDim2.new(0,8,0.5,-14)
    ic.BackgroundTransparency=1;ic.Text=icon;ic.TextSize=18;ic.Font=Enum.Font.Gotham

    -- Título
    local tl=Instance.new("TextLabel",frame)
    tl.Size=UDim2.new(1,-105,0,18);tl.Position=UDim2.new(0,40,0,6)
    tl.BackgroundTransparency=1;tl.Text=title
    tl.TextColor3=Color3.new(1,1,1);tl.TextSize=12;tl.Font=Enum.Font.GothamBold
    tl.TextXAlignment=Enum.TextXAlignment.Left

    -- Descrição
    local dl=Instance.new("TextLabel",frame)
    dl.Size=UDim2.new(1,-105,0,14);dl.Position=UDim2.new(0,40,0,26)
    dl.BackgroundTransparency=1;dl.Text=desc
    dl.TextColor3=Color3.fromRGB(130,110,180);dl.TextSize=10;dl.Font=Enum.Font.Gotham
    dl.TextXAlignment=Enum.TextXAlignment.Left

    -- Botão toggle
    local tbtn=Instance.new("TextButton",frame)
    tbtn.Size=UDim2.new(0,52,0,26);tbtn.Position=UDim2.new(1,-62,0.5,-13)
    tbtn.BackgroundColor3=Color3.fromRGB(30,20,60)
    tbtn.Text="OFF";tbtn.TextColor3=Color3.fromRGB(130,100,180)
    tbtn.TextSize=11;tbtn.Font=Enum.Font.GothamBold
    tbtn.BorderSizePixel=0;tbtn.AutoButtonColor=false
    Instance.new("UICorner",tbtn).CornerRadius=UDim.new(0,8)

    local function updateVisual()
        local on = CFG[key]
        if on then
            tbtn.Text="ON"
            tbtn.BackgroundColor3=color
            tbtn.TextColor3=Color3.new(1,1,1)
            fs.Color=color
        else
            tbtn.Text="OFF"
            tbtn.BackgroundColor3=Color3.fromRGB(30,20,60)
            tbtn.TextColor3=Color3.fromRGB(130,100,180)
            fs.Color=Color3.fromRGB(35,20,80)
        end
    end

    tbtn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        updateVisual()
        if onToggle then onToggle(CFG[key]) end
    end)

    toggleRefs[key] = updateVisual
    return frame
end

-- Toggle 1: Auto-Max
makeToggle(win, TOGGLE_Y_START, "autoMax",
    "🔋","AUTO-MAX","Usa 100% do poder do executor",
    Color3.fromRGB(255,160,0))

-- Toggle 2: ReadableOnly
makeToggle(win, TOGGLE_Y_START+54, "readableOnly",
    "👁️","SÓ LEGÍVEIS","Descarta scripts não descompilados",
    Color3.fromRGB(60,200,120))

-- Toggle 3: SelfDecomp
makeToggle(win, TOGGLE_Y_START+108, "selfDecomp",
    "🧠","SELF-DECOMP","Decompile interno independente do executor",
    Color3.fromRGB(80,140,255))

-- Toggle 4: Filter (abre painel extra)
local filterPanelVisible = false
local filterPanel        -- declarado depois

local filterToggleFrame = makeToggle(win, TOGGLE_Y_START+162, "filterEnabled",
    "🔍","FILTRO DE NOMES","Salva só scripts com nomes específicos",
    Color3.fromRGB(255,80,180),
    function(on)
        filterPanel.Visible = on
        filterPanelVisible  = on
        -- Redimensiona janela
        win.Size = UDim2.new(0,450,0, on and 720 or 620)
    end
)

-- ══════════════════════════════════════════════════════════════════
--  PAINEL DE FILTRO
-- ══════════════════════════════════════════════════════════════════
filterPanel = Instance.new("Frame",win)
filterPanel.Size = UDim2.new(1,-18,0,118)
filterPanel.Position = UDim2.new(0,9,0,TOGGLE_Y_START+216)
filterPanel.BackgroundColor3 = Color3.fromRGB(10,6,24)
filterPanel.BorderSizePixel = 0
filterPanel.Visible = false
Instance.new("UICorner",filterPanel).CornerRadius=UDim.new(0,10)
local fpStroke=Instance.new("UIStroke",filterPanel)
fpStroke.Color=Color3.fromRGB(255,80,180);fpStroke.Thickness=1

mkLbl(filterPanel,{
    Text="📝  Nomes para filtrar (um por linha):",
    TextSize=11,Font=Enum.Font.GothamBold,
    Size=UDim2.new(1,-10,0,18),Position=UDim2.new(0,8,0,6),
    TextColor3=Color3.fromRGB(255,140,210),
    TextXAlignment=Enum.TextXAlignment.Left,
})
mkLbl(filterPanel,{
    Text="Ex:  GetItem | MainScript | PlayerData | Shop",
    TextSize=10,Font=Enum.Font.Code,
    Size=UDim2.new(1,-10,0,14),Position=UDim2.new(0,8,0,24),
    TextColor3=Color3.fromRGB(140,100,170),
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- Caixa de texto (multilinha simulada com TextBox)
local filterBox = Instance.new("TextBox",filterPanel)
filterBox.Size = UDim2.new(1,-16,0,52)
filterBox.Position = UDim2.new(0,8,0,42)
filterBox.BackgroundColor3 = Color3.fromRGB(6,3,15)
filterBox.TextColor3 = Color3.new(1,1,1)
filterBox.PlaceholderText = "GetItem\nMainScript\nPlayerData\nShop"
filterBox.PlaceholderColor3 = Color3.fromRGB(80,60,110)
filterBox.TextSize = 12
filterBox.Font = Enum.Font.Code
filterBox.MultiLine = true
filterBox.ClearTextOnFocus = false
filterBox.TextWrapped = false
filterBox.TextXAlignment = Enum.TextXAlignment.Left
filterBox.TextYAlignment = Enum.TextYAlignment.Top
filterBox.BorderSizePixel = 0
filterBox.Text = ""
Instance.new("UICorner",filterBox).CornerRadius=UDim.new(0,8)
local fbStroke=Instance.new("UIStroke",filterBox)
fbStroke.Color=Color3.fromRGB(100,50,160);fbStroke.Thickness=1

-- Botão aplicar filtro
local applyBtn = Instance.new("TextButton",filterPanel)
applyBtn.Size = UDim2.new(1,-16,0,22)
applyBtn.Position = UDim2.new(0,8,0,98)
applyBtn.BackgroundColor3 = Color3.fromRGB(200,60,160)
applyBtn.Text = "✓  APLICAR FILTRO"
applyBtn.TextColor3 = Color3.new(1,1,1)
applyBtn.TextSize = 11
applyBtn.Font = Enum.Font.GothamBold
applyBtn.BorderSizePixel = 0
Instance.new("UICorner",applyBtn).CornerRadius=UDim.new(0,7)
applyBtn.AutoButtonColor = false
applyBtn.MouseEnter:Connect(function() applyBtn.BackgroundColor3=Color3.fromRGB(235,80,185) end)
applyBtn.MouseLeave:Connect(function() applyBtn.BackgroundColor3=Color3.fromRGB(200,60,160) end)

-- Contador de filtros ativos
local filterCountLbl = mkLbl(filterPanel,{
    Text="",TextSize=10,Font=Enum.Font.Code,
    Size=UDim2.new(1,-10,0,12),Position=UDim2.new(0,8,0,86),
    TextColor3=Color3.fromRGB(255,160,210),
    TextXAlignment=Enum.TextXAlignment.Left,
})

applyBtn.MouseButton1Click:Connect(function()
    CFG.filterNames = {}
    for line in (filterBox.Text.."\n"):gmatch("([^\n]*)\n") do
        local trimmed = line:match("^%s*(.-)%s*$")
        -- Remove prefixo "-" se tiver (estilo lista)
        trimmed = trimmed:gsub("^%-+%s*","")
        if #trimmed > 0 then
            table.insert(CFG.filterNames, trimmed)
        end
    end
    filterCountLbl.Text = string.format("✓ %d termo(s) carregados", #CFG.filterNames)
    applyBtn.BackgroundColor3 = Color3.fromRGB(30,160,80)
    applyBtn.Text = "✓  APLICADO!"
    task.delay(1.5, function()
        applyBtn.BackgroundColor3 = Color3.fromRGB(200,60,160)
        applyBtn.Text = "✓  APLICAR FILTRO"
    end)
end)

-- ══════════════════════════════════════════════════════════════════
--  BARRA DE PROGRESSO + STATUS
-- ══════════════════════════════════════════════════════════════════
local UI_BASE_Y = TOGGLE_Y_START + 216 -- base sem filtro

-- Esses elementos ficam dinâmicos em Y (abaixo dos toggles)
local phaseLbl = mkLbl(win,{
    Text="Aguardando...",TextSize=11,Font=Enum.Font.Gotham,
    Size=UDim2.new(1,-18,0,15),Position=UDim2.new(0,9,0,UI_BASE_Y),
    TextColor3=Color3.fromRGB(165,136,225),
    TextXAlignment=Enum.TextXAlignment.Left,
})
local pbg=Instance.new("Frame",win)
pbg.Size=UDim2.new(1,-18,0,20);pbg.Position=UDim2.new(0,9,0,UI_BASE_Y+17)
pbg.BackgroundColor3=Color3.fromRGB(13,8,30);pbg.BorderSizePixel=0;pbg.ClipsDescendants=true
Instance.new("UICorner",pbg).CornerRadius=UDim.new(0,10)
local pbar=Instance.new("Frame",pbg)
pbar.Size=UDim2.new(0,0,1,0);pbar.BackgroundColor3=Color3.fromRGB(88,44,215)
pbar.BorderSizePixel=0
Instance.new("UICorner",pbar).CornerRadius=UDim.new(0,10)
local pbG=Instance.new("UIGradient",pbar)
pbG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(88,44,215)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(152,62,250)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(52,182,255)),
})
local pctLbl=Instance.new("TextLabel",pbg)
pctLbl.Size=UDim2.new(1,0,1,0);pctLbl.BackgroundTransparency=1
pctLbl.Text="0%";pctLbl.TextColor3=Color3.new(1,1,1)
pctLbl.TextSize=11;pctLbl.Font=Enum.Font.GothamBold

local stLbl=mkLbl(win,{
    Text="Pronto. Configure os toggles e clique INICIAR.",
    TextSize=11,Font=Enum.Font.Gotham,
    Size=UDim2.new(1,-18,0,15),Position=UDim2.new(0,9,0,UI_BASE_Y+39),
    TextColor3=Color3.fromRGB(135,112,195),
    TextXAlignment=Enum.TextXAlignment.Left,
})
local spdLbl=mkLbl(win,{
    Text="",TextSize=10,Font=Enum.Font.Code,
    Size=UDim2.new(1,-18,0,13),Position=UDim2.new(0,9,0,UI_BASE_Y+56),
    TextColor3=Color3.fromRGB(68,198,128),
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- Log
local logF=Instance.new("ScrollingFrame",win)
logF.Size=UDim2.new(1,-18,0,74);logF.Position=UDim2.new(0,9,0,UI_BASE_Y+72)
logF.BackgroundColor3=Color3.fromRGB(5,3,12);logF.BorderSizePixel=0
logF.ScrollBarThickness=3;logF.ScrollBarImageColor3=Color3.fromRGB(62,26,148)
logF.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UICorner",logF).CornerRadius=UDim.new(0,8)
local logLL=Instance.new("UIListLayout",logF)
logLL.SortOrder=Enum.SortOrder.LayoutOrder;logLL.Padding=UDim.new(0,1)
local logN=0

local function addLog(msg,col)
    logN=logN+1
    local l=Instance.new("TextLabel",logF)
    l.Size=UDim2.new(1,-6,0,15);l.BackgroundTransparency=1
    l.Text="> "..tostring(msg)
    l.TextColor3=col or Color3.fromRGB(132,202,162)
    l.TextSize=11;l.Font=Enum.Font.Code
    l.TextXAlignment=Enum.TextXAlignment.Left;l.LayoutOrder=logN
    logF.CanvasSize=UDim2.new(0,0,0,logLL.AbsoluteContentSize.Y+8)
    logF.CanvasPosition=Vector2.new(0,math.huge)
end

-- Botão salvar
local btn=Instance.new("TextButton",win)
btn.Size=UDim2.new(1,-18,0,44);btn.Position=UDim2.new(0,9,0,UI_BASE_Y+150)
btn.BackgroundColor3=Color3.fromRGB(76,30,200)
btn.Text="⚡  INICIAR SAVE  ⚡"
btn.TextColor3=Color3.new(1,1,1);btn.TextSize=15;btn.Font=Enum.Font.GothamBold
btn.BorderSizePixel=0;btn.AutoButtonColor=false
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,12)
local bG=Instance.new("UIGradient",btn)
bG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(96,40,230)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(42,142,252)),
})
bG.Rotation=90
Instance.new("UIStroke",btn).Color=Color3.fromRGB(122,62,250)

-- Label executor
local exeLbl=mkLbl(win,{
    Text="",TextSize=9,Font=Enum.Font.Code,
    Size=UDim2.new(1,-18,0,24),Position=UDim2.new(0,9,0,UI_BASE_Y+198),
    TextColor3=Color3.fromRGB(90,72,138),
    TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
})
exeLbl.Text=string.format(
    "write=%s  decomp=%s  dumpstr=%s  bytecode=%s  getgc=%s  identity=%s",
    EXE.writefile and "✓" or "✗",
    (EXE.decompile or EXE.decomp) and "✓" or "✗",
    EXE.dumpstring and "✓" or "✗",
    EXE.getscriptbytecode and "✓" or "✗",
    EXE.getgc and "✓" or "✗",
    EXE.setthreadidentity and "✓" or "✗"
)

-- ── UI helpers ────────────────────────────────────────────────
local function setProgress(p)
    p=math.clamp(p,0,100)
    pbar.Size=UDim2.new(p/100,0,1,0)
    pctLbl.Text=string.format("%.1f%%",p)
end
local function setPhase(s)  phaseLbl.Text=tostring(s) end
local function setStatus(s) stLbl.Text=tostring(s) end
local function setSpeed(s)  spdLbl.Text=tostring(s) end

-- ══════════════════════════════════════════════════════════════════
--  SAVE PRINCIPAL
-- ══════════════════════════════════════════════════════════════════
local saving=false

local function doSave()
    if saving then return end
    saving=true

    btn.Text="⏳  Processando..."
    btn.BackgroundColor3=Color3.fromRGB(32,32,58)
    setProgress(0)

    local modeStr = {}
    if CFG.autoMax      then modeStr[#modeStr+1]="AutoMax" end
    if CFG.readableOnly then modeStr[#modeStr+1]="SóLegíveis" end
    if CFG.selfDecomp   then modeStr[#modeStr+1]="SelfDecomp" end
    if CFG.filterEnabled then modeStr[#modeStr+1]="Filtro("..#CFG.filterNames..")" end
    local modeInfo = #modeStr>0 and table.concat(modeStr," | ") or "Padrão"

    addLog("=== v4 ULTIMATE | "..modeInfo.." ===",Color3.fromRGB(255,210,50))
    setPhase("Fase 1/5 — Varrendo...")
    task.wait(0.04)

    -- FASE 1: Varredura
    local t0=os.clock()
    local scripts,locals,modules,remotes={},{},{},{}
    local RC={
        RemoteEvent=true,RemoteFunction=true,
        UnreliableRemoteEvent=true,
        BindableEvent=true,BindableFunction=true,
    }

    local ok,desc=pcall(function() return game:GetDescendants() end)
    if not ok then
        addLog("ERRO: GetDescendants falhou!",Color3.fromRGB(255,55,55))
        saving=false; return
    end

    for _,obj in ipairs(desc) do
        local c=obj.ClassName
        if not SKIP[c] then
            if     c=="Script"       then scripts[#scripts+1]=obj
            elseif c=="LocalScript"  then locals[#locals+1]=obj
            elseif c=="ModuleScript" then modules[#modules+1]=obj
            elseif RC[c]             then remotes[#remotes+1]=obj
            end
        end
    end

    local scanMs=math.floor((os.clock()-t0)*1000)
    addLog(string.format("Varredura: %dms | SCR=%d LOC=%d MOD=%d REM=%d",
        scanMs,#scripts,#locals,#modules,#remotes),Color3.fromRGB(88,212,255))

    -- Aplica filtro nos scripts (não afeta remotes)
    local function applyFilter(list)
        if not CFG.filterEnabled or #CFG.filterNames==0 then return list end
        local out={}
        for _,s in ipairs(list) do
            if passesFilter(s.Name) then out[#out+1]=s end
        end
        return out
    end
    scripts = applyFilter(scripts)
    locals  = applyFilter(locals)
    modules = applyFilter(modules)

    if CFG.filterEnabled then
        addLog(string.format("Após filtro: SCR=%d LOC=%d MOD=%d",
            #scripts,#locals,#modules),Color3.fromRGB(255,100,190))
    end

    cardVals[1].Text=tostring(#scripts)
    cardVals[2].Text=tostring(#locals)
    cardVals[3].Text=tostring(#modules)
    cardVals[4].Text=tostring(#remotes)
    setProgress(5); task.wait(0.02)

    -- FASE 2: Pastas
    setPhase("Fase 2/5 — Pastas")
    mkdirs(); setProgress(8); task.wait(0.02)

    local TOTAL=#scripts+#locals+#modules+1
    local DONE=0; local tSave=os.clock()
    local skipped=0

    local function tick(label)
        DONE=DONE+1
        local pct=8+(DONE/TOTAL)*89
        setProgress(pct)
        local el=os.clock()-tSave
        local rate=el>0 and (DONE/el) or 0
        setSpeed(string.format("%.0f/s | %d/%d | %.1fs | skip=%d",rate,DONE,TOTAL,el,skipped))
        setStatus(label)
        if DONE%10==0 then task.wait() end
    end

    -- FASE 3: Scripts
    setPhase("Fase 3/5 — Scripts ("..#scripts..")")
    addLog("Salvando Scripts...",Color3.fromRGB(172,132,255))
    local regS={}
    for _,s in ipairs(scripts) do
        local src,readable=fullDecompile(s)
        if src then
            safeWrite(F_SCR.."/"..uniqueName(regS,realName(s),".lua"),src)
        else
            skipped=skipped+1
        end
        tick("📜 "..s.Name..(readable and "" or " [skip]"))
    end
    addLog(string.format("Scripts: OK (%d) skip=%d",#scripts,skipped),Color3.fromRGB(95,250,140))

    -- FASE 4a: LocalScripts
    local sk2=0
    setPhase("Fase 4a/5 — LocalScripts ("..#locals..")")
    addLog("Salvando LocalScripts...",Color3.fromRGB(122,172,255))
    local regL={}
    for _,s in ipairs(locals) do
        local src,readable=fullDecompile(s)
        if src then
            safeWrite(F_LOC.."/"..uniqueName(regL,realName(s),".lua"),src)
        else
            sk2=sk2+1; skipped=skipped+1
        end
        tick("📋 "..s.Name)
    end
    addLog(string.format("LocalScripts: OK (%d) skip=%d",#locals,sk2),Color3.fromRGB(95,250,140))

    -- FASE 4b: ModuleScripts
    local sk3=0
    setPhase("Fase 4b/5 — ModuleScripts ("..#modules..")")
    addLog("Salvando ModuleScripts...",Color3.fromRGB(198,110,255))
    local regM={}
    for _,s in ipairs(modules) do
        local src,readable=fullDecompile(s)
        if src then
            safeWrite(F_MOD.."/"..uniqueName(regM,realName(s),".lua"),src)
        else
            sk3=sk3+1; skipped=skipped+1
        end
        tick("🧩 "..s.Name)
    end
    addLog(string.format("ModuleScripts: OK (%d) skip=%d",#modules,sk3),Color3.fromRGB(95,250,140))

    -- FASE 5: Remotes.txt
    setPhase("Fase 5/5 — Remotes.txt")
    addLog("Compilando Remotes.txt...",Color3.fromRGB(46,208,168))
    do
        local groups={
            RemoteEvent={},RemoteFunction={},
            UnreliableRemoteEvent={},
            BindableEvent={},BindableFunction={},
        }
        local order={"RemoteEvent","RemoteFunction","UnreliableRemoteEvent","BindableEvent","BindableFunction"}
        for _,r in ipairs(remotes) do
            local g=groups[r.ClassName]; if g then g[#g+1]=r end
        end
        local buf={
            "╔══════════════════════════════════════════════════════════════╗",
            "║         SAVE INSTANCES v4 ULTIMATE — Remotes.txt            ║",
            string.format("║  Gerado : %-50s║",os.date("%d/%m/%Y  %H:%M:%S")),
            string.format("║  Total  : %-50s║",#remotes.." remote(s)"),
            "╚══════════════════════════════════════════════════════════════╝","",
        }
        for _,tn in ipairs(order) do
            local g=groups[tn]
            if g and #g>0 then
                buf[#buf+1]=string.format("▶  %s  (%d)",tn,#g)
                buf[#buf+1]=string.rep("─",56)
                for idx,r in ipairs(g) do
                    buf[#buf+1]=string.format("  [%d]  %s",idx,r.Name)
                    buf[#buf+1]=string.format("       Path  : %s",fullPath(r))
                    buf[#buf+1]=string.format("       Class : %s",r.ClassName)
                    buf[#buf+1]=""
                end
                buf[#buf+1]=""
            end
        end
        safeWrite(F_REM,table.concat(buf,"\n"))
        tick("📡 Remotes.txt")
    end

    -- FINALIZAÇÃO
    local elapsed=os.clock()-tSave
    setProgress(100)
    setPhase("✅ Concluído!")
    setStatus(string.format("Salvo em %.1fs | pasta: %s",elapsed,ROOT))
    setSpeed(string.format("Média: %.0f items/s | Total: %d | Descartados: %d",
        TOTAL/math.max(elapsed,0.1),
        #scripts+#locals+#modules+#remotes,
        skipped
    ))
    addLog("══════════════════════════",Color3.fromRGB(88,198,255))
    addLog(string.format("✅ DONE em %.2fs",elapsed),Color3.fromRGB(52,248,112))
    addLog("Scripts:  "..#scripts,Color3.fromRGB(182,255,182))
    addLog("Locals:   "..#locals, Color3.fromRGB(182,255,182))
    addLog("Modules:  "..#modules,Color3.fromRGB(182,255,182))
    addLog("Remotes:  "..#remotes,Color3.fromRGB(182,255,182))
    if skipped>0 then
        addLog("Descartados: "..skipped.." (ilegíveis/sem match)",Color3.fromRGB(255,195,55))
    end
    addLog("Pasta: "..ROOT,Color3.fromRGB(255,212,52))

    btn.Text="✅  SAVE CONCLUÍDO"
    btn.BackgroundColor3=Color3.fromRGB(20,130,62)
    task.delay(5,function()
        if sg and sg.Parent then
            btn.Text="⚡  INICIAR SAVE  ⚡"
            btn.BackgroundColor3=Color3.fromRGB(76,30,200)
            saving=false
        end
    end)
end

btn.MouseEnter:Connect(function() if not saving then btn.BackgroundColor3=Color3.fromRGB(96,46,242) end end)
btn.MouseLeave:Connect(function() if not saving then btn.BackgroundColor3=Color3.fromRGB(76,30,200) end end)
btn.MouseButton1Click:Connect(function() task.spawn(doSave) end)

-- Logs iniciais
if not EXE.writefile then
    addLog("⚠ writefile ausente — sem gravação real",Color3.fromRGB(255,162,42))
end
if EXE.decompile or EXE.decomp then
    addLog("✓ decompile() detectado",Color3.fromRGB(52,228,108))
elseif EXE.dumpstring then
    addLog("✓ dumpstring detectado",Color3.fromRGB(52,228,108))
elseif EXE.getscriptbytecode then
    addLog("⚠ Apenas bytecode disponível",Color3.fromRGB(255,198,52))
else
    addLog("✗ Sem API de decompile — use SelfDecomp",Color3.fromRGB(255,72,72))
end
addLog("v4 pronto. Configure toggles → INICIAR.",Color3.fromRGB(132,162,255))
