Fix violation ban/resource not original from official:: fix 3/7day ban

Need analize and integrated with your file

-- SKUY_EIGENFIX_v4: _SKUY_HOOK registry-based hook (idempotent + traceable).
-- Primary eigeninfo spoof layer: hook LobbySystem.SendEigeninfo, clean table,
-- call original. EIGEN_SPOOF v5 at Tss layer remains as defense-in-depth.
-- ============================================================================
pcall(function()
    local _pcall = pcall
    local _HookRegistry = {}
    local function _SKUY_HOOK(tbl, key, wrapperFactory)
        if type(tbl) ~= "table" then return end
        local orig = tbl[key]
        if orig and _HookRegistry[orig] then return end
        local newFn = wrapperFactory(orig)
        if type(orig) == "function" then
            _HookRegistry[newFn] = _HookRegistry[orig] or orig
        end
        tbl[key] = newFn
    end
    local SPOOF_PATTERNS = { "mrpcs", "_al64_", "_al32_", "al64_", "al32_" }
    local cleanCache = {}
    local function getCleanBlob(len)
        local L = tonumber(len) or 120833
        if L <= 0 then L = 1 end
        if L > 200000 then L = 200000 end
        if not cleanCache[L] then cleanCache[L] = string.rep("0", L) end
        return cleanCache[L], L
    end
    local function shouldSpoof(infoName)
        local n = tostring(infoName or ""):lower()
        for _, pat in ipairs(SPOOF_PATTERNS) do
            if n:find(pat, 1, true) then return true end
        end
        return false
    end
    local function cleanEigeninfoTable(eigeninfo)
        if type(eigeninfo) ~= "table" then return eigeninfo end
        local cleaned = {}
        for k, v in pairs(eigeninfo) do
            if type(v) == "table" and v.file_name ~= nil and v.eigenvalue ~= nil then
                if shouldSpoof(v.file_name) then
                    local ev = tostring(v.eigenvalue)
                    local cleanBlob, cleanLen = getCleanBlob(#ev)
                    cleaned[k] = { file_name = v.file_name, eigenvalue = cleanBlob, crc = v.crc }
                else
                    cleaned[k] = v
                end
            else
                cleaned[k] = v
            end
        end
        return cleaned
    end
    local function install()
        local LS = rawget(_G, "LobbySystem") or package.loaded["client.logic.login.logic_lobby"]
        if type(LS) ~= "table" then return false end
        if type(LS.SendEigeninfo) ~= "function" then return false end
        _SKUY_HOOK(LS, "SendEigeninfo", function(orig)
            return function(eigeninfo, call_from_type)
                local ok, cleaned = _pcall(cleanEigeninfoTable, eigeninfo)
                if not ok then cleaned = eigeninfo end
                return orig(cleaned, call_from_type)
            end
        end)
        return true
    end
    _pcall(function()
    local tt = package.loaded["common.time_ticker"]

    if tt and type(tt.AddTimerLoop) == "function" then
        local h = tt.AddTimerLoop(0, function()
            _pcall(function()
                install()
            end)
        end, -1, 0.15)
    end
end)
    end
end)