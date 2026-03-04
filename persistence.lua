local bitser = require "bitser"
local C = require "constants"
local M = {}

function M.save(filename, slot, S)
    local save_table = {
        notes      = S.notes,
        instrument = S.instrument,
        plocks     = S.plocks,
        reverb     = S.reverb,
        tempo      = S.tempo,
    }
    love.filesystem.write(filename .. slot, bitser.dumps(save_table))
end

function M.load(filename, slot)
    local savefile = love.filesystem.read(filename .. slot)
    if savefile == nil then return nil end
    return bitser.loads(savefile)
end

-- Resolve notes/instrument/plocks/reverb/tempo from either named or legacy positional format.
local function unpack_table(t)
    if t.notes ~= nil then
        return t.notes, t.instrument, t.plocks, t.reverb, t.tempo
    else
        return t[1], t[2], t[3], t[4], t[5]
    end
end

-- Public alias so callers (e.g. keys.lua) can avoid duplicating legacy-format detection.
M.unpack = unpack_table

function M.apply_full(S, t)
    local t_notes, t_instrument, t_plocks, t_reverb, t_tempo = unpack_table(t)
    S.notes      = t_notes
    S.instrument = t_instrument
    S.plocks     = t_plocks
    S.reverb     = t_reverb
    S.tempo      = t_tempo
    for i = 1, C.TRACKS do
        for j = 1, C.STEPS do
            S.instrument_change[i][j] = true
        end
    end
    for i = 1, C.REVERB_PARAMS do
        S.reverb_change[i] = true
    end
    S.tempo_change = true
end

function M.apply_track(S, t, track)
    local t_notes, t_instrument, t_plocks, t_reverb, t_tempo = unpack_table(t)
    S.notes[track]      = t_notes[track]
    S.instrument[track] = t_instrument[track]
    for y, row in ipairs(t_plocks) do
        S.plocks[y][track] = row[track]
    end
    S.reverb = t_reverb
    S.tempo  = t_tempo
    for i = 1, C.STEPS do
        S.instrument_change[track][i] = true
    end
    for i = 1, C.REVERB_PARAMS do
        S.reverb_change[i] = true
    end
    S.tempo_change = true
end

function M.check_patterns(S)
    for i = 1, C.STEPS do
        local savefile = love.filesystem.read(S.filename .. i)
        if savefile == nil then
            M.save(S.filename, i, S)
        else
            local save_table = bitser.loads(savefile)
            local t_notes = save_table.notes or save_table[1]
            for y = 1, C.TRACKS do
                for x = 1, C.STEPS do
                    if t_notes[y][x] > 0 then
                        S.save_patterns[y][i] = true
                    end
                end
            end
        end
    end
end

return M
