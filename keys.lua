local S = require "state"
local C = require "constants"
local persistence = require "persistence"

local function change(var, value, limit)
    var = var + value
    if ((var > limit) and (value > 0)) or ((var < limit) and (value < 0)) then
        var = limit
    end
    return var
end

local function enternotes(var, value1, limit1, value2, limit2)
    if love.keyboard.isDown("q") then
        S.canDelete = true
        S.notes[S.cur_y][S.cur_x] = change(S.notes[S.cur_y][S.cur_x], value1, limit1)
        S.last_note[S.cur_y] = S.notes[S.cur_y][S.cur_x]
    else
        var = change(var, value2, limit2)
    end
    return var
end

local function plockIncrease(value)
    S.togglePlock = true
    S.plocks[S.inst_nb][S.cur_y][S.cur_x] = change(S.plocks[S.inst_nb][S.cur_y][S.cur_x], value, C.get_param_limit(S.inst_nb))
end

local function adjust_param_or_cursor(cursor_var, delta, cursor_delta, cursor_limit)
    if love.keyboard.isDown("q") then
        if S.inst_nb <= C.PARAM_INSTR_MAX then
            S.instrument[S.cur_y][S.inst_nb] = change(S.instrument[S.cur_y][S.inst_nb], delta,
                delta > 0 and C.get_param_limit(S.inst_nb) or 0)
            S.instrument_change[S.cur_y][S.inst_nb] = true
        elseif S.inst_nb <= C.PARAM_REVERB_MAX then
            local reverb_idx = S.cur_x_instr - C.REVERB_OFFSET
            local lim
            if delta > 0 then
                lim = (reverb_idx == 4) and 1 or C.DEFAULT_LIMIT
            else
                lim = 0
            end
            S.reverb[reverb_idx] = change(S.reverb[reverb_idx], delta, lim)
            S.reverb_change[reverb_idx] = true
        elseif S.inst_nb <= C.PARAM_TEMPO then
            S.tempo = change(S.tempo, delta, delta > 0 and C.DEFAULT_LIMIT or 0)
            S.tempo_change = true
        end
    else
        cursor_var = change(cursor_var, cursor_delta, cursor_limit)
    end
    return cursor_var
end

function love.keypressed(key)
    S.inst_nb = (S.cur_y_instr - 1) * C.STEPS + S.cur_x_instr

    if not S.stateSave then
        if not S.stateInstrument then
            if key == "left" then
                S.cur_x = enternotes(S.cur_x, -C.OCTAVE, C.OCTAVE, -1, 1)
            elseif key == "right" then
                S.cur_x = enternotes(S.cur_x, C.OCTAVE, 10 * C.OCTAVE, 1, C.STEPS)
            elseif key == "up" then
                S.cur_y = enternotes(S.cur_y, 1, 10 * C.OCTAVE, -1, 1)
            elseif key == "down" then
                S.cur_y = enternotes(S.cur_y, -1, C.OCTAVE, 1, C.TRACKS)
            elseif key == "q" and S.notes[S.cur_y][S.cur_x] < 0 then
                S.canDelete = true
                S.notes[S.cur_y][S.cur_x] = S.last_note[S.cur_y]
            end
        elseif not S.statePlock then
            if key == "left" then
                S.cur_x_instr = adjust_param_or_cursor(S.cur_x_instr, -10, -1, 1)
            elseif key == "down" then
                S.cur_y_instr = adjust_param_or_cursor(S.cur_y_instr, -1, 1, 2)
            elseif key == "right" then
                S.cur_x_instr = adjust_param_or_cursor(S.cur_x_instr, 10, 1, C.STEPS)
            elseif key == "up" then
                S.cur_y_instr = adjust_param_or_cursor(S.cur_y_instr, 1, -1, 1)
            end
        else
            if key == "left" then
                if love.keyboard.isDown("q") and S.notes[S.cur_y][S.cur_x] > 0 then
                    S.togglePlock = true
                    S.plocks[S.inst_nb][S.cur_y][S.cur_x] = change(S.plocks[S.inst_nb][S.cur_y][S.cur_x], -10, 0)
                else
                    S.cur_x = change(S.cur_x, -1, 1)
                end
            elseif key == "right" then
                if love.keyboard.isDown("q") and S.notes[S.cur_y][S.cur_x] > 0 then
                    plockIncrease(10)
                else
                    S.cur_x = change(S.cur_x, 1, C.STEPS)
                end
            elseif key == "up" and S.notes[S.cur_y][S.cur_x] > 0 and love.keyboard.isDown("q") then
                plockIncrease(1)
            elseif key == "down" and S.notes[S.cur_y][S.cur_x] > 0 and love.keyboard.isDown("q") then
                S.togglePlock = true
                S.plocks[S.inst_nb][S.cur_y][S.cur_x] = change(S.plocks[S.inst_nb][S.cur_y][S.cur_x], -1, 0)
            elseif key == "q" and S.plocks[S.inst_nb][S.cur_y][S.cur_x] < 0 then
                S.togglePlock = true
                S.plocks[S.inst_nb][S.cur_y][S.cur_x] = S.instrument[S.cur_y][S.inst_nb]
            end
        end

        if key == "s" and S.stateInstrument then
            S.statePlock = not S.statePlock
        elseif key == "x" then
            S.stateInstrument = not S.stateInstrument
            S.statePlock = false
        end
    else
        if key == "left" then
            S.cur_x = change(S.cur_x, -1, 1)
        elseif key == "right" then
            S.cur_x = change(S.cur_x, 1, C.STEPS)
        elseif key == "up" then
            if love.keyboard.isDown("q") then
                local t = persistence.load(S.filename, S.cur_x)
                persistence.apply_full(S, t)
                for i = 1, C.STEPS do
                    S.active_pattern[i] = S.cur_x
                end
            elseif love.keyboard.isDown("w") then
                local t = persistence.load(S.filename, S.cur_x)
                persistence.apply_track(S, t, S.cur_y)
                S.active_pattern[S.cur_y] = S.cur_x
            else
                S.cur_y = change(S.cur_y, -1, 1)
            end
        elseif key == "down" then
            if love.keyboard.isDown("q") then
                persistence.save(S.filename, S.cur_x, S)
                for i = 1, C.STEPS do
                    S.active_pattern[i] = S.cur_x
                end
                persistence.check_patterns(S)
            elseif love.keyboard.isDown("w") then
                local t = persistence.load(S.filename, S.cur_x)
                local save_notes, save_instrument, save_plocks, save_reverb, save_tempo =
                    persistence.unpack(t)
                save_notes[S.cur_y]      = S.notes[S.cur_y]
                save_instrument[S.cur_y] = S.instrument[S.cur_y]
                for y, row in ipairs(S.plocks) do
                    save_plocks[y][S.cur_y] = row[S.cur_y]
                end
                save_reverb = S.reverb
                save_tempo  = S.tempo
                persistence.save(S.filename, S.cur_x, {
                    notes      = save_notes,
                    instrument = save_instrument,
                    plocks     = save_plocks,
                    reverb     = save_reverb,
                    tempo      = save_tempo,
                })
                S.active_pattern[S.cur_y] = S.cur_x
                persistence.check_patterns(S)
            else
                S.cur_y = change(S.cur_y, 1, C.TRACKS)
            end
        end
    end

    if key == "z" then
        S.stateSave = not S.stateSave
        S.stateInstrument = false
        S.statePlock = false
    end
end

function love.keyreleased(key)
    if key == "q" then
        if not S.stateInstrument and not S.stateSave then
            if not S.canDelete then
                S.last_note[S.cur_y] = S.notes[S.cur_y][S.cur_x]
                S.notes[S.cur_y][S.cur_x] = -S.notes[S.cur_y][S.cur_x]
            else
                S.canDelete = false
            end
        elseif S.statePlock then
            if not S.togglePlock then
                S.plocks[S.inst_nb][S.cur_y][S.cur_x] = -1
            else
                S.togglePlock = false
            end
        end
    end
end
