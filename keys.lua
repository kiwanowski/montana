local C = require "constants"
local Persistence = require "persistence"

local PARAM_LIMITS = {
    [6] = 47,
    [9] = 2,
    [17] = 5, [19] = 5, [21] = 5, [23] = 5
}

local function get_param_limit(param_id)
    return PARAM_LIMITS[param_id] or C.DEFAULT_PARAM_MAX
end

local function change(var, value, limit)
    var = var + value
    if ((var > limit) and (value > 0)) or ((var < limit) and (value < 0)) then
        var = limit
    end
    return var
end

local function enternotes(var, value1, limit1, value2, limit2)
    if love.keyboard.isDown("q") then
        canDelete = true
        notes[cur_y][cur_x] = change(notes[cur_y][cur_x], value1, limit1)
        last_note[cur_y] = notes[cur_y][cur_x]
    else
        var = change(var, value2, limit2)
    end
    return var
end

local function instrDecrease(var, value1, value2, limit)
    if love.keyboard.isDown("q") then
        if inst_nb < 25 then
            instrument[cur_y][inst_nb] = change(instrument[cur_y][inst_nb], value1, 0)
            instrument_change[cur_y][inst_nb] = true
        elseif inst_nb < 30 then
            reverb[cur_x_instr - 8] = change(reverb[cur_x_instr - 8], value1, 0)
            reverb_change[cur_x_instr - 8] = true
        elseif inst_nb < 31 then
            tempo = change(tempo, value1, 0)
            tempo_change = true
        end
    else
        var = change(var, value2, limit)
    end
    return var
end

local function instrIncrease(var, value1, value2, limit)
    if love.keyboard.isDown("q") then
        if inst_nb < 25 then
            instrument_change[cur_y][inst_nb] = true
            instrument[cur_y][inst_nb] = change(instrument[cur_y][inst_nb], value1, get_param_limit(inst_nb))
        elseif inst_nb < 30 then
            reverb_change[cur_x_instr - 8] = true
            if (cur_x_instr - 8) == 4 then
                reverb[cur_x_instr - 8] = change(reverb[cur_x_instr - 8], value1, 1)
            else
                reverb[cur_x_instr - 8] = change(reverb[cur_x_instr - 8], value1, C.DEFAULT_PARAM_MAX)
            end
        elseif inst_nb < 31 then
            tempo = change(tempo, value1, C.DEFAULT_PARAM_MAX)
            tempo_change = true
        end
    else
        var = change(var, value2, limit)
    end
    return var
end

local function plockIncrease(value)
    togglePlock = true
    plocks[inst_nb][cur_y][cur_x] = change(plocks[inst_nb][cur_y][cur_x], value, get_param_limit(inst_nb))
end

local function handle_note_mode(key)
    if key == "left" then
        cur_x = enternotes(cur_x, -12, 12, -1, 1)
    elseif key == "right" then
        cur_x = enternotes(cur_x, 12, 120, 1, C.NUM_STEPS)
    elseif key == "up" then
        cur_y = enternotes(cur_y, 1, 120, -1, 1)
    elseif key == "down" then
        cur_y = enternotes(cur_y, -1, 12, 1, C.NUM_TRACKS)
    elseif key == "q" and notes[cur_y][cur_x] < 0 then
        canDelete = true
        notes[cur_y][cur_x] = last_note[cur_y]
    end
end

local function handle_instrument_mode(key)
    if key == "left" then
        cur_x_instr = instrDecrease(cur_x_instr, -10, -1, 1)
    elseif key == "down" then
        cur_y_instr = instrDecrease(cur_y_instr, -1, 1, 2)
    elseif key == "right" then
        cur_x_instr = instrIncrease(cur_x_instr, 10, 1, C.NUM_STEPS)
    elseif key == "up" then
        cur_y_instr = instrIncrease(cur_y_instr, 1, -1, 1)
    end
end

local function handle_plock_mode(key)
    if key == "left" then
        if love.keyboard.isDown("q") and notes[cur_y][cur_x] > 0 then
            togglePlock = true
            plocks[inst_nb][cur_y][cur_x] = change(plocks[inst_nb][cur_y][cur_x], -10, 0)
        else
            cur_x = change(cur_x, -1, 1)
        end
    elseif key == "right" then
        if love.keyboard.isDown("q") and notes[cur_y][cur_x] > 0 then
            plockIncrease(10)
        else
            cur_x = change(cur_x, 1, C.NUM_STEPS)
        end
    elseif key == "up" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
        plockIncrease(1)
    elseif key == "down" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
        togglePlock = true
        plocks[inst_nb][cur_y][cur_x] = change(plocks[inst_nb][cur_y][cur_x], -1, 0)
    elseif key == "q" and plocks[inst_nb][cur_y][cur_x] < 0 then
        togglePlock = true
        plocks[inst_nb][cur_y][cur_x] = instrument[cur_y][inst_nb]
    end
end

local function handle_save_mode(key)
    if key == "left" then
        cur_x = change(cur_x, -1, 1)
    elseif key == "right" then
        cur_x = change(cur_x, 1, C.NUM_STEPS)
    elseif key == "up" then
        if love.keyboard.isDown("q") then
            local data = Persistence.load_all(filename, cur_x)
            notes = data[1]
            instrument = data[2]
            plocks = data[3]
            reverb = data[4]
            tempo = data[5]
            for i = 1, C.NUM_TRACKS do
                for j = 1, C.NUM_PARAMS do
                    instrument_change[i][j] = true
                end
            end
            for i = 1, C.NUM_REVERB do
                reverb_change[i] = true
            end
            tempo_change = true
            for i = 1, C.NUM_STEPS do
                active_pattern[i] = cur_x
            end
        elseif love.keyboard.isDown("w") then
            local track_data = Persistence.load_track(filename, cur_x, cur_y)
            notes[cur_y] = track_data.notes
            instrument[cur_y] = track_data.instrument
            for param_idx, steps in ipairs(track_data.plocks_col) do
                plocks[param_idx][cur_y] = steps
            end
            reverb = track_data.reverb
            tempo = track_data.tempo
            for i = 1, C.NUM_PARAMS do
                instrument_change[cur_y][i] = true
            end
            for i = 1, C.NUM_REVERB do
                reverb_change[i] = true
            end
            tempo_change = true
            active_pattern[cur_y] = cur_x
        else
            cur_y = change(cur_y, -1, 1)
        end
    elseif key == "down" then
        if love.keyboard.isDown("q") then
            Persistence.save_all(filename, cur_x, notes, instrument, plocks, reverb, tempo)
            for i = 1, C.NUM_STEPS do
                active_pattern[i] = cur_x
            end
            check_patterns()
        elseif love.keyboard.isDown("w") then
            Persistence.save_track(filename, cur_x, cur_y, notes, instrument, plocks, reverb, tempo)
            active_pattern[cur_y] = cur_x
            check_patterns()
        else
            cur_y = change(cur_y, 1, C.NUM_TRACKS)
        end
    end
end

function love.keypressed(key)
    inst_nb = (cur_y_instr - 1) * C.NUM_STEPS + cur_x_instr

    if stateSave then
        handle_save_mode(key)
    else
        if not stateInstrument then
            handle_note_mode(key)
        elseif not statePlock then
            handle_instrument_mode(key)
        else
            handle_plock_mode(key)
        end

        if key == "s" and stateInstrument then
            statePlock = not statePlock
        elseif key == "x" then
            stateInstrument = not stateInstrument
            statePlock = false
        end
    end

    if key == "z" then
        stateSave = not stateSave
        stateInstrument = false
        statePlock = false
    end
end

function love.keyreleased(key)
    if key == "q" then
        if not stateInstrument and not stateSave then
            if not canDelete then
                last_note[cur_y] = notes[cur_y][cur_x]
                notes[cur_y][cur_x] = -notes[cur_y][cur_x]
            else
                canDelete = false
            end
        elseif statePlock then
            if not togglePlock then
                plocks[inst_nb][cur_y][cur_x] = C.NO_PLOCK
            else
                togglePlock = false
            end
        end
    end
end