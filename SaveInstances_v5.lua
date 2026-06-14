-- ╔══════════════════════════════════════════════════════════════════╗
-- ║       SAVE INSTANCES PRO  v5  — RedzLib Edition                 ║
-- ║  Filter • ReadableOnly • AutoMax • SelfDecomp • Cascade Decomp  ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ── Carrega a biblioteca ──────────────────────────────────────────
local redzlib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/minhdepzai-v/LibraryRobloc/refs/heads/main/RedzLibrary.lua"
))()

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
--  CONFIGURAÇÕES (controladas pelos toggles da GUI)
-- ══════════════════════════════════════════════════════════════════
local CFG = {
    autoMax       = false,
    readableOnly  = false,
    selfDecomp    = false,
    filterEnabled = false,
    filterNames   = {},
}

-- ══════════════════════════════════════════════════════════════════
--  PASTAS DE SAÍDA
-- ══════════════════════════════════════════════════════════════════
local ROOT  = "SaveInstances_v5"
local F_SCR = ROOT .. "/Scripts"
local F_LOC = ROOT .. "/LocalScripts"
local F_MOD = ROOT .. "/ModuleScripts"
local F_REM = ROOT .. "/Remotes.txt"

-- ══════════════════════════════════════════════════════════════════
--  CLASSES IGNORADAS (só partes visuais/físicas)
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
--  FILTRO POR NOME
--  Match exato → contém → trigrama (3 letras consecutivas)
-- ══════════════════════════════════════════════════════════════════
local function passesFilter(name)
    if not CFG.filterEnabled or #CFG.filterNames == 0 then return true end
    local ln = name:lower()
    for _, term in ipairs(CFG.filterNames) do
        local lt = term:lower()
        if ln == lt then return true end
        if ln:find(lt, 1, true) then return true end
        if lt:find(ln, 1, true) then return true end
        if #lt >= 3 then
            for i = 1, #lt - 2 do
                if ln:find(lt:sub(i, i+2), 1, true) then return true end
            end
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════
--  DETECTOR DE LEGIBILIDADE
-- ══════════════════════════════════════════════════════════════════
local LUA_KW = {
    "local ","function ","end","return","if ","then","else",
    "for ","while ","do","repeat","until","pairs","ipairs",
    "require","game:","workspace","script","print(","warn(",
}
local function isReadable(src)
    if type(src) ~= "string" or #src < 15 then return false end
    if src:sub(1,1) == "\27" then return false end
    local np = 0
    for i = 1, math.min(#src, 300) do
        local b = src:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then np = np+1 end
    end
    if np / math.min(#src, 300) > 0.3 then return false end
    local hits = 0
    for _, kw in ipairs(LUA_KW) do
        if src:find(kw, 1, true) then
            hits = hits+1
            if hits >= 2 then return true end
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════
--  SELF-DECOMPILER  (6 técnicas independentes do executor)
-- ══════════════════════════════════════════════════════════════════
local function selfDecompile(obj)
    -- T1: .Source
    do
        local ok, s = pcall(function() return obj.Source end)
        if ok and isReadable(s) then return "-- [Self: .Source]\n"..s end
    end
    -- T2: GC closure
    if EXE.getgc then
        local ok, gc = pcall(getgc, true)
        if ok and gc then
            for _, v in ipairs(gc) do
                if type(v)=="function" then
                    local ok2, info = pcall(function()
                        return debug and debug.getinfo and debug.getinfo(v,"S")
                    end)
                    if ok2 and info and info.source then
                        local s = tostring(info.source)
                        if s:find(obj.Name, 1, true) and isReadable(s) then
                            return "-- [Self: GC closure]\n"..s
                        end
                    end
                end
            end
        end
    end
    -- T3: getloadedmodules
    if EXE.getloadedmodules and obj.ClassName=="ModuleScript" then
        local ok, mods = pcall(getloadedmodules)
        if ok and mods then
            for _, m in ipairs(mods) do
                if m == obj then
                    local ok2, s = pcall(function() return m.Source end)
                    if ok2 and isReadable(s) then return "-- [Self: loadedmodule]\n"..s end
                end
            end
        end
    end
    -- T4: getrenv upvalues
    if EXE.getrenv then
        local ok, env = pcall(getrenv)
        if ok and env then
            local buf = {"-- [Self: getrenv upvalues]"}
            local n = 0
            for k, v in pairs(env) do
                if type(k)=="string" and not k:match("^_") then
                    local tv = type(v)
                    if tv=="function" or tv=="table" or tv=="string" then
                        buf[#buf+1] = string.format("-- %s = (%s)", k, tv)
                        n = n+1
                    end
                end
                if n > 80 then break end
            end
            if n > 0 then return table.concat(buf,"\n") end
        end
    end
    -- T5: identity elevada + decompile
    if EXE.setthreadidentity and EXE.decompile then
        local prev = 3
        if EXE.getthreadidentity then pcall(function() prev = getthreadidentity() end) end
        pcall(setthreadidentity, 8)
        local ok, s = pcall(decompile, obj)
        pcall(setthreadidentity, prev)
        if ok and isReadable(s) then return "-- [Self: identity8+decompile]\n"..s end
    end
    -- T6: strings do bytecode
    if EXE.getscriptbytecode then
        local ok, bc = pcall(getscriptbytecode, obj)
        if ok and type(bc)=="string" and #bc>0 then
            local strs, cur = {}, ""
            for i = 1, #bc do
                local b = bc:byte(i)
                if b >= 32 and b < 127 then
                    cur = cur..string.char(b)
                else
                    if #cur >= 4 then strs[#strs+1] = cur end
                    cur = ""
                end
            end
            if #cur >= 4 then strs[#strs+1] = cur end
            if #strs > 0 then
                local buf = {"-- [Self: bytecode string extraction]",""}
                for i, s in ipairs(strs) do
                    if i > 200 then buf[#buf+1]="-- ..."; break end
                    buf[#buf+1] = "-- "..s
                end
                return table.concat(buf,"\n")
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
--  AUTO-MAX  (usa 100% do executor, escolhe o resultado mais longo)
-- ══════════════════════════════════════════════════════════════════
local function autoMaxDecomp(obj)
    if EXE.setthreadidentity then pcall(setthreadidentity, 8) end
    local results = {}
    local function try(label, fn)
        local ok, s = pcall(fn)
        if ok and type(s)=="string" and #s>10 then
            results[#results+1] = { score=#s, src="-- [AutoMax: "..label.."]\n"..s }
        end
    end
    if EXE.decompile         then try("decompile",    function() return decompile(obj) end) end
    if EXE.decomp            then try("decomp",       function() return decomp(obj)    end) end
    if EXE.dumpstring and EXE.getscriptbytecode then
        try("dumpstring", function()
            local bc = getscriptbytecode(obj)
            return dumpstring(bc)
        end)
    end
    if EXE.decompile and EXE.setthreadidentity then
        for _, id in ipairs({8,7,6}) do
            pcall(setthreadidentity, id)
            local ok, s = pcall(decompile, obj)
            if ok and type(s)=="string" and #s>10 then
                results[#results+1] = { score=#s*1.05, src=string.format("-- [AutoMax: id%d]\n",id)..s }
            end
        end
    end
    if EXE.setthreadidentity then pcall(setthreadidentity, 3) end
    if #results == 0 then return nil end
    table.sort(results, function(a,b) return a.score > b.score end)
    return results[1].src
end

-- ══════════════════════════════════════════════════════════════════
--  DECOMPILE PRINCIPAL — cascata completa
-- ══════════════════════════════════════════════════════════════════
local function fullDecompile(obj)
    local parts, cur = {}, obj
    while cur and cur ~= game do table.insert(parts,1,tostring(cur.Name)); cur=cur.Parent end
    local header = string.format(
        "-- Script : %s\n-- Path   : %s\n-- Class  : %s\n%s\n",
        obj.Name, table.concat(parts,"."), obj.ClassName, string.rep("-",60)
    )
    local src = nil

    -- AutoMax primeiro (se ativo)
    if CFG.autoMax then
        src = autoMaxDecomp(obj)
        if src and (not CFG.readableOnly or isReadable(src)) then
            return header..src, true
        end
        src = nil
    end

    -- Cascata padrão
    if not src and EXE.decompile then
        local ok,s = pcall(decompile, obj)
        if ok and type(s)=="string" and #s>10 then src=s end
    end
    if not src and EXE.decomp then
        local ok,s = pcall(decomp, obj)
        if ok and type(s)=="string" and #s>10 then src=s end
    end
    if not src and EXE.dumpstring and EXE.getscriptbytecode then
        local ok,bc = pcall(getscriptbytecode, obj)
        if ok and type(bc)=="string" then
            local ok2,s = pcall(dumpstring, bc)
            if ok2 and type(s)=="string" and #s>10 then src=s end
        end
    end
    if not src then
        local ok,s = pcall(function() return obj.Source end)
        if ok and type(s)=="string" and #s>10 then src=s end
    end

    -- SelfDecomp como reforço
    if CFG.selfDecomp and (not src or (CFG.readableOnly and not isReadable(src))) then
        local sd = selfDecompile(obj)
        if sd and (not CFG.readableOnly or isReadable(sd)) then src=sd end
    end

    if not src then
        if CFG.readableOnly then return nil, false end
        if EXE.getscriptbytecode then
            local ok,bc = pcall(getscriptbytecode, obj)
            if ok and type(bc)=="string" and #bc>0 then
                local hex={}
                for i=1,math.min(#bc,2048) do hex[i]=string.format("%02X",bc:byte(i)) end
                return header.."-- [bytecode raw]\n--[[\n"..table.concat(hex," ").."\n--]]\n", false
            end
        end
        return header.."-- [nenhum método disponível]\n", false
    end

    if CFG.readableOnly and not isReadable(src) then return nil, false end
    return header..src, true
end

-- ══════════════════════════════════════════════════════════════════
--  HELPERS DE ARQUIVO
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
local function safeWrite(path, content)
    if not EXE.writefile then return end
    if not pcall(writefile, path, tostring(content)) then
        pcall(writefile, path:gsub("[^%w%./_ %-]","_"), tostring(content))
    end
end
local function fullPath(obj)
    local p,c={},obj
    while c and c~=game do table.insert(p,1,tostring(c.Name)); c=c.Parent end
    return table.concat(p," > ")
end

-- ══════════════════════════════════════════════════════════════════
--  VARIÁVEIS DE ESTADO DO SAVE
-- ══════════════════════════════════════════════════════════════════
local saving       = false
local lastStats    = { scr=0, loc=0, mod=0, rem=0, skip=0, time=0 }
local filterText   = ""  -- texto bruto da caixa de filtro

-- ══════════════════════════════════════════════════════════════════
--  FUNÇÃO DE SAVE PRINCIPAL
-- ══════════════════════════════════════════════════════════════════
local logCallback  = nil   -- será preenchido pela GUI

local function doSave(logFn, doneFn)
    if saving then return end
    saving = true

    local function L(msg) if logFn then logFn(msg) end end

    L("=== SAVE INSTANCES v5 INICIADO ===")
    local modeStr = {}
    if CFG.autoMax       then modeStr[#modeStr+1]="AutoMax"        end
    if CFG.readableOnly  then modeStr[#modeStr+1]="SóLegíveis"     end
    if CFG.selfDecomp    then modeStr[#modeStr+1]="SelfDecomp"     end
    if CFG.filterEnabled then modeStr[#modeStr+1]="Filtro("..#CFG.filterNames..")" end
    L("Modo: "..(#modeStr>0 and table.concat(modeStr," | ") or "Padrão"))
    task.wait(0.05)

    -- Varredura
    L("Varrendo instâncias...")
    local t0 = os.clock()
    local scripts, locals, modules, remotes = {},{},{},{}
    local RC = {
        RemoteEvent=true, RemoteFunction=true,
        UnreliableRemoteEvent=true,
        BindableEvent=true, BindableFunction=true,
    }
    local ok, desc = pcall(function() return game:GetDescendants() end)
    if not ok then L("ERRO: GetDescendants falhou!"); saving=false; return end

    for _, obj in ipairs(desc) do
        local c = obj.ClassName
        if not SKIP[c] then
            if     c=="Script"       then scripts[#scripts+1]=obj
            elseif c=="LocalScript"  then locals[#locals+1]=obj
            elseif c=="ModuleScript" then modules[#modules+1]=obj
            elseif RC[c]             then remotes[#remotes+1]=obj
            end
        end
    end
    L(string.format("Varredura: %.0fms | S=%d L=%d M=%d R=%d",
        (os.clock()-t0)*1000, #scripts, #locals, #modules, #remotes))

    -- Filtro
    if CFG.filterEnabled and #CFG.filterNames > 0 then
        local function filt(list)
            local out={}
            for _,s in ipairs(list) do
                if passesFilter(s.Name) then out[#out+1]=s end
            end
            return out
        end
        scripts = filt(scripts)
        locals  = filt(locals)
        modules = filt(modules)
        L(string.format("Após filtro: S=%d L=%d M=%d", #scripts,#locals,#modules))
    end

    mkdirs()

    local TOTAL   = #scripts + #locals + #modules + 1
    local DONE    = 0
    local skipped = 0
    local tSave   = os.clock()

    local function tick(label)
        DONE = DONE+1
        if DONE % 10 == 0 then task.wait() end
        L(label)
    end

    -- Scripts
    L("─── Salvando Scripts (" .. #scripts .. ")...")
    local regS={}
    for _, s in ipairs(scripts) do
        local src, ok2 = fullDecompile(s)
        if src then safeWrite(F_SCR.."/"..uniqueName(regS,realName(s),".lua"), src)
        else skipped=skipped+1 end
        tick("📜 "..s.Name)
    end

    -- LocalScripts
    L("─── Salvando LocalScripts (" .. #locals .. ")...")
    local regL={}
    for _, s in ipairs(locals) do
        local src, ok2 = fullDecompile(s)
        if src then safeWrite(F_LOC.."/"..uniqueName(regL,realName(s),".lua"), src)
        else skipped=skipped+1 end
        tick("📋 "..s.Name)
    end

    -- ModuleScripts
    L("─── Salvando ModuleScripts (" .. #modules .. ")...")
    local regM={}
    for _, s in ipairs(modules) do
        local src, ok2 = fullDecompile(s)
        if src then safeWrite(F_MOD.."/"..uniqueName(regM,realName(s),".lua"), src)
        else skipped=skipped+1 end
        tick("🧩 "..s.Name)
    end

    -- Remotes.txt
    L("─── Compilando Remotes.txt...")
    do
        local groups = {
            RemoteEvent={},RemoteFunction={},
            UnreliableRemoteEvent={},
            BindableEvent={},BindableFunction={},
        }
        local order = {"RemoteEvent","RemoteFunction","UnreliableRemoteEvent","BindableEvent","BindableFunction"}
        for _, r in ipairs(remotes) do
            local g=groups[r.ClassName]; if g then g[#g+1]=r end
        end
        local buf = {
            "╔══════════════════════════════════════════════════════════╗",
            "║      SAVE INSTANCES v5 — Remotes.txt                    ║",
            string.format("║  Gerado : %-46s║", os.date("%d/%m/%Y %H:%M:%S")),
            string.format("║  Total  : %-46s║", #remotes.." remote(s)"),
            "╚══════════════════════════════════════════════════════════╝","",
        }
        for _, tn in ipairs(order) do
            local g=groups[tn]
            if g and #g>0 then
                buf[#buf+1]=string.format("▶  %s  (%d)",tn,#g)
                buf[#buf+1]=string.rep("─",52)
                for idx,r in ipairs(g) do
                    buf[#buf+1]=string.format("  [%d]  %s",idx,r.Name)
                    buf[#buf+1]=string.format("       Path : %s",fullPath(r))
                    buf[#buf+1]=""
                end
                buf[#buf+1]=""
            end
        end
        safeWrite(F_REM, table.concat(buf,"\n"))
        tick("📡 Remotes.txt")
    end

    local elapsed = os.clock()-tSave
    lastStats = { scr=#scripts, loc=#locals, mod=#modules, rem=#remotes, skip=skipped, time=elapsed }

    L(string.format("✅ CONCLUÍDO em %.2fs | Skip=%d | Pasta: %s", elapsed, skipped, ROOT))
    saving = false
    if doneFn then doneFn() end
end

-- ══════════════════════════════════════════════════════════════════
--  JANELA REDZLIB
-- ══════════════════════════════════════════════════════════════════
local Window = redzlib:MakeWindow({
    Title      = "Save Instances Pro",
    SubTitle   = "v5 Ultimate Edition",
    SaveFolder = "SaveInstances_v5_settings.lua",
})

Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://71014873973869", BackgroundTransparency = 0 },
    Corner = { CornerRadius = UDim.new(35, 1) },
})

-- ══════════════════════════════════════════════════════════════════
--  ABA 1 — SAVE
-- ══════════════════════════════════════════════════════════════════
local TabSave = Window:MakeTab({"💾  Save", "rbxassetid://7072706663"})
Window:SelectTab(TabSave)

TabSave:AddParagraph({
    "ℹ️  Como usar",
    "Configure os toggles na aba <font color='rgb(140,100,255)'>Opções</font>, "..
    "adicione filtros na aba <font color='rgb(255,100,180)'>Filtro</font> e "..
    "clique em <font color='rgb(80,200,120)'>INICIAR SAVE</font>."
})

TabSave:AddSection({"📊  Status do Executor"})

-- Parágrafo dinâmico com capacidades do executor
local exeInfo = string.format(
    "write: <font color='rgb(%s)'>%s</font>  decomp: <font color='rgb(%s)'>%s</font>  "..
    "dumpstr: <font color='rgb(%s)'>%s</font>  bytecode: <font color='rgb(%s)'>%s</font>  "..
    "getgc: <font color='rgb(%s)'>%s</font>  identity: <font color='rgb(%s)'>%s</font>",
    EXE.writefile         and "80,220,120" or "220,80,80", EXE.writefile         and "✓" or "✗",
    (EXE.decompile or EXE.decomp) and "80,220,120" or "220,80,80", (EXE.decompile or EXE.decomp) and "✓" or "✗",
    EXE.dumpstring        and "80,220,120" or "220,80,80", EXE.dumpstring        and "✓" or "✗",
    EXE.getscriptbytecode and "80,220,120" or "220,80,80", EXE.getscriptbytecode and "✓" or "✗",
    EXE.getgc             and "80,220,120" or "220,80,80", EXE.getgc             and "✓" or "✗",
    EXE.setthreadidentity and "80,220,120" or "220,80,80", EXE.setthreadidentity and "✓" or "✗"
)
TabSave:AddParagraph({"Capacidades", exeInfo})

TabSave:AddSection({"🚀  Ação"})

-- Log box via Paragraph (atualizado durante o save)
local logPara = TabSave:AddParagraph({"📋  Log", "Aguardando início..."})
local logLines = {}
local function pushLog(msg)
    table.insert(logLines, msg)
    if #logLines > 12 then table.remove(logLines, 1) end
    if logPara and logPara.SetValue then
        logPara:SetValue(table.concat(logLines, "\n"))
    end
end

-- Botão principal
TabSave:AddButton({"⚡  INICIAR SAVE", function()
    if saving then
        pushLog("⚠ Já está salvando, aguarde...")
        return
    end
    logLines = {}
    task.spawn(function()
        doSave(pushLog, function()
            pushLog(string.format(
                "📊 Scripts=%d | Locals=%d | Modules=%d | Remotes=%d | Skip=%d | %.1fs",
                lastStats.scr, lastStats.loc, lastStats.mod,
                lastStats.rem, lastStats.skip, lastStats.time
            ))
        end)
    end)
end})

-- ══════════════════════════════════════════════════════════════════
--  ABA 2 — OPÇÕES  (Toggles)
-- ══════════════════════════════════════════════════════════════════
local TabOpts = Window:MakeTab({"⚙️  Opções", "rbxassetid://7072706663"})

TabOpts:AddSection({"🔋  Decompile"})

TabOpts:AddToggle({
    Name        = "AUTO-MAX",
    Description = "Usa <font color='rgb(255,190,50)'>100%</font> do executor — eleva identidade e escolhe o melhor resultado",
    Default     = false,
    Callback    = function(v)
        CFG.autoMax = v
    end
})

TabOpts:AddToggle({
    Name        = "SELF-DECOMP",
    Description = "6 técnicas independentes do executor: .Source, GC, loadedmodules, getrenv, identity, bytecode",
    Default     = false,
    Callback    = function(v)
        CFG.selfDecomp = v
    end
})

TabOpts:AddSection({"👁️  Qualidade"})

TabOpts:AddToggle({
    Name        = "SÓ LEGÍVEIS",
    Description = "Descarta scripts que <font color='rgb(220,80,80)'>não foram descompilados</font> de forma legível",
    Default     = false,
    Callback    = function(v)
        CFG.readableOnly = v
    end
})

TabOpts:AddSection({"📁  Pasta de saída"})

TabOpts:AddParagraph({
    "Onde os arquivos são salvos",
    "<font color='rgb(140,200,255)'>"..ROOT.."/</font>\n"..
    "  Scripts/        → Scripts\n"..
    "  LocalScripts/   → LocalScripts\n"..
    "  ModuleScripts/  → ModuleScripts\n"..
    "  Remotes.txt     → Todos os Remotes"
})

-- ══════════════════════════════════════════════════════════════════
--  ABA 3 — FILTRO
-- ══════════════════════════════════════════════════════════════════
local TabFilter = Window:MakeTab({"🔍  Filtro", "rbxassetid://7072706663"})

TabFilter:AddSection({"🔍  Filtro por Nome"})

TabFilter:AddToggle({
    Name        = "ATIVAR FILTRO",
    Description = "Quando ativo, salva <font color='rgb(255,100,180)'>apenas</font> scripts cujo nome bate com os termos abaixo",
    Default     = false,
    Callback    = function(v)
        CFG.filterEnabled = v
    end
})

TabFilter:AddParagraph({
    "ℹ️  Como funciona o match",
    "• Nome <font color='rgb(140,220,140)'>exato</font> — ex: 'GetItem'\n"..
    "• <font color='rgb(140,220,140)'>Contém</font> o termo — ex: 'PlayerGetItem'\n"..
    "• <font color='rgb(140,220,140)'>3 letras</font> consecutivas em comum — ex: 'Get' dentro de 'GetWeapon'\n"..
    "• Não diferencia maiúsculas/minúsculas"
})

TabFilter:AddSection({"📝  Termos do Filtro"})

TabFilter:AddParagraph({
    "Como adicionar",
    "Digite os nomes na caixa abaixo, <font color='rgb(255,210,50)'>um por linha</font>.\n"..
    "Exemplo:\n"..
    "  GetItem\n"..
    "  PlayerData\n"..
    "  ShopModule\n"..
    "Depois clique em <font color='rgb(80,200,120)'>APLICAR FILTRO</font>."
})

-- Caixa de texto para os termos
local filterBoxRef = TabFilter:AddTextBox({
    Name            = "Nomes (um por linha)",
    Description     = "Digite os termos separados por Enter",
    PlaceholderText = "GetItem\nPlayerData\nShopModule",
    Callback        = function(v)
        filterText = v
    end
})

-- Botão aplicar
TabFilter:AddButton({"✓  APLICAR FILTRO", function()
    CFG.filterNames = {}
    for line in (filterText.."\n"):gmatch("([^\n]*)\n") do
        local t = line:match("^%s*(.-)%s*$"):gsub("^%-+%s*","")
        if #t > 0 then CFG.filterNames[#CFG.filterNames+1] = t end
    end

    -- Feedback visual via paragraph
    local nomes = ""
    for i, n in ipairs(CFG.filterNames) do
        nomes = nomes .. "  • " .. n .. "\n"
        if i >= 15 then nomes = nomes.."  ...\n"; break end
    end

    -- Atualiza log da aba Save
    pushLog(string.format("✓ Filtro aplicado: %d termo(s)", #CFG.filterNames))
end})

-- Parágrafo de feedback do filtro
local filterStatusPara = TabFilter:AddParagraph({
    "Status do Filtro",
    "Nenhum filtro aplicado ainda."
})

-- Botão limpar filtro
TabFilter:AddButton({"🗑️  LIMPAR FILTRO", function()
    CFG.filterNames = {}
    filterText = ""
    if filterBoxRef and filterBoxRef.SetValue then filterBoxRef:SetValue("") end
    if filterStatusPara and filterStatusPara.SetValue then
        filterStatusPara:SetValue("Filtro limpo.")
    end
    pushLog("Filtro limpo.")
end})

-- ══════════════════════════════════════════════════════════════════
--  ABA 4 — SOBRE
-- ══════════════════════════════════════════════════════════════════
local TabAbout = Window:MakeTab({"📌  Sobre", "rbxassetid://7072706663"})

TabAbout:AddParagraph({
    "Save Instances Pro  v5",
    "Interface: <font color='rgb(140,100,255)'>RedzLibrary</font>\n"..
    "Engine: <font color='rgb(255,210,50)'>Cascade Decompiler v5</font>"
})

TabAbout:AddSection({"⚙️  Sistemas"})

TabAbout:AddParagraph({"🔋 AUTO-MAX",
    "Eleva a identidade do thread ao máximo (8) e roda todas as APIs de decompile disponíveis "..
    "no executor. Guarda o resultado com mais conteúdo."})

TabAbout:AddParagraph({"🧠 SELF-DECOMP",
    "6 técnicas independentes: .Source, GC closures, loadedmodules, "..
    "getrenv upvalues, identity+decompile e string extraction do bytecode."})

TabAbout:AddParagraph({"👁️ SÓ LEGÍVEIS",
    "Detecta automaticamente se o resultado do decompile é código Lua real "..
    "(keywords, sem bytecode puro, sem lixo). Descarta o que não passar."})

TabAbout:AddParagraph({"🔍 FILTRO DE NOMES",
    "Match em 3 níveis: nome exato → contém o termo → 3 letras consecutivas em comum. "..
    "Não diferencia maiúsculas/minúsculas."})

TabAbout:AddSection({"📂  Estrutura de pastas"})

TabAbout:AddParagraph({"Onde tudo é salvo",
    ROOT.."/\n"..
    "  ├── Scripts/\n"..
    "  ├── LocalScripts/\n"..
    "  ├── ModuleScripts/\n"..
    "  └── Remotes.txt"})
