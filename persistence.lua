local bitser = require 'bitser'
local Persistence = {}

function Persistence.save_all(filename, slot, notes, instrument, plocks, reverb, tempo)
    love.filesystem.write(filename .. slot, bitser.dumps({notes, instrument, plocks, reverb, tempo}))
end

function Persistence.load_all(filename, slot)
    local data = love.filesystem.read(filename .. slot)
    if data == nil then return nil end
    return bitser.loads(data)
end

function Persistence.save_track(filename, slot, track_idx, notes, instrument, plocks, reverb, tempo)
    local data = Persistence.load_all(filename, slot)
    if data == nil then return end
    data[1][track_idx] = notes[track_idx]
    data[2][track_idx] = instrument[track_idx]
    for param_idx, track_plocks in ipairs(plocks) do
        data[3][param_idx][track_idx] = track_plocks[track_idx]
    end
    data[4] = reverb
    data[5] = tempo
    love.filesystem.write(filename .. slot, bitser.dumps(data))
end

function Persistence.load_track(filename, slot, track_idx)
    local data = Persistence.load_all(filename, slot)
    if data == nil then return nil end
    local plocks_col = {}
    for param_idx, track_plocks in ipairs(data[3]) do
        plocks_col[param_idx] = track_plocks[track_idx]
    end
    return {
        notes = data[1][track_idx],
        instrument = data[2][track_idx],
        plocks_col = plocks_col,
        reverb = data[4],
        tempo = data[5]
    }
end

return Persistence
