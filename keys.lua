function love.keypressed(key)
    inst_nb = (cur_y_instr - 1) * 16 + cur_x_instr

    if not stateSave then
        if not stateInstrument then
            if key == "left" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = decrement(notes[cur_y][cur_x], 12, 12)
                    last_note[cur_y] = notes[cur_y][cur_x]
                else
                    cur_x = decrement(cur_x, 1, 1)
                end
            elseif key == "right" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = increment(notes[cur_y][cur_x], 12, 120)
                    last_note[cur_y] = notes[cur_y][cur_x]
                else
                    cur_x = increment(cur_x, 1, 16)
                end
            elseif key == "up" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = increment(notes[cur_y][cur_x], 1, 120)
                    last_note[cur_y] = notes[cur_y][cur_x]
                else
                    cur_y = decrement(cur_y, 1, 1)
                end
            elseif key == "down" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = decrement(notes[cur_y][cur_x], 1, 12)
                    last_note[cur_y] = notes[cur_y][cur_x]
                else
                    cur_y = increment(cur_y, 1, 8)
                end
            elseif key == "q" and notes[cur_y][cur_x] < 0 then
                canDelete = true
                notes[cur_y][cur_x] = last_note[cur_y]
            end
        elseif not statePlock then
            if key == "left" then
                if love.keyboard.isDown("q") then
                    if inst_nb < 25 then
                        instrument[cur_y][inst_nb] = decrement(instrument[cur_y][inst_nb], 10, 0)
                        instrument_change[cur_y][inst_nb] = true
                    elseif inst_nb < 30 then
                        reverb[cur_x_instr - 8] = decrement(reverb[cur_x_instr - 8], 10, 0)
                        reverb_change[cur_x_instr - 8] = true
                    else
                        tempo = decrement(tempo, 10, 0)
                        tempo_change = true
                    end
                else
                    cur_x_instr = decrement(cur_x_instr, 1, 1)
                end
            elseif key == "right" then
                if love.keyboard.isDown("q") then
                    if inst_nb < 25 then
                        instrument_change[cur_y][inst_nb] = true
                        if inst_nb == 6 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 10, 47)
                        elseif inst_nb == 9 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 10, 2)
                        elseif inst_nb == 17 or inst_nb == 19 or inst_nb == 21 or inst_nb == 23 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 10, 5)
                        else
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 10, 255)
                        end
                    elseif inst_nb < 30 then
                        reverb_change[cur_x_instr - 8] = true
                        if (cur_x_instr - 8) == 4 then
                            reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 10, 1)
                        else
                            reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 10, 255)
                        end
                    else
                        tempo = increment(tempo, 10, 255)
                        tempo_change = true
                    end
                else
                    cur_x_instr = increment(cur_x_instr, 1, 16)
                end
            elseif key == "up" then
                if love.keyboard.isDown("q") then
                    if inst_nb < 25 then
                        instrument_change[cur_y][inst_nb] = true
                        if inst_nb == 6 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 1, 47)
                        elseif inst_nb == 9 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 1, 2)
                        elseif inst_nb == 17 or inst_nb == 19 or inst_nb == 21 or inst_nb == 23 then
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 1, 5)
                        else
                            instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 1, 255)
                        end
                    elseif inst_nb < 30 then
                        reverb_change[cur_x_instr - 8] = true
                        if (cur_x_instr - 8) == 4 then
                            reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 1, 1)
                        else
                            reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 1, 255)
                        end
                    else
                        tempo = increment(tempo, 1, 255)
                        tempo_change = true
                    end
                else
                    cur_y_instr = decrement(cur_y_instr, 1, 1)
                end
            elseif key == "down" then
                if love.keyboard.isDown("q") then
                    if inst_nb < 25 then
                        instrument[cur_y][inst_nb] = decrement(instrument[cur_y][inst_nb], 1, 0)
                        instrument_change[cur_y][inst_nb] = true
                    elseif inst_nb < 30 then
                        reverb[cur_x_instr - 8] = decrement(reverb[cur_x_instr - 8], 1, 0)
                        reverb_change[cur_x_instr - 8] = true
                    else
                        tempo = decrement(tempo, 1, 0)
                        tempo_change = true
                    end
                else
                    cur_y_instr = increment(cur_y_instr, 1, 2)
                end
            end
        else
            if key == "left" then
                if love.keyboard.isDown("q") and notes[cur_y][cur_x] > 0 then
                    togglePlock = true
                    plocks[inst_nb][cur_y][cur_x] = decrement(plocks[inst_nb][cur_y][cur_x], 10, 0)
                else
                    cur_x = decrement(cur_x, 1, 1)
                end
            elseif key == "right" then
                if love.keyboard.isDown("q") and notes[cur_y][cur_x] > 0 then
                    togglePlock = true
                    if inst_nb == 6 then
                        plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 10, 47)
                    elseif inst_nb == 9 then
                        plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 10, 2)
                    elseif inst_nb == 17 or inst_nb == 19 or inst_nb == 21 or inst_nb == 23 then
                        plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 10, 5)
                    else
                        plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 10, 255)
                    end
                else
                    cur_x = increment(cur_x, 1, 16)
                end
            elseif key == "up" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
                togglePlock = true
                if inst_nb == 6 then
                    plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 1, 47)
                elseif inst_nb == 9 then
                    plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 1, 2)
                elseif inst_nb == 17 or inst_nb == 19 or inst_nb == 21 or inst_nb == 23 then
                    plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 1, 5)
                else
                    plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 1, 255)
                end
            elseif key == "down" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
                togglePlock = true
                plocks[inst_nb][cur_y][cur_x] = decrement(plocks[inst_nb][cur_y][cur_x], 1, 0)
            elseif key == "q" and plocks[inst_nb][cur_y][cur_x] < 0 then
                togglePlock = true
                plocks[inst_nb][cur_y][cur_x] = instrument[cur_y][inst_nb]
            end
        end

        if key == "s" and stateInstrument then
            statePlock = not statePlock
        elseif key == "x" then
            stateInstrument = not stateInstrument
            statePlock = false
        end
    else
        if key == "left" then
            cur_x = decrement(cur_x, 1, 1)
        elseif key == "right" then
            cur_x = increment(cur_x, 1, 16)
        elseif key == "up" then
            if love.keyboard.isDown("q") then
                save_table = bitser.loads(love.filesystem.read(filename .. cur_x))
                notes = save_table[1]
                instrument = save_table[2]
                plocks = save_table[3]
                reverb = save_table[4]
                tempo = save_table[5]
                for i = 1, 8 do
                    for j = 1, 16 do
                        instrument_change[i][j] = true
                    end
                end
                for i = 1, 5 do
                    reverb_change[i] = true
                end
                tempo_change = true
                for i = 1, 16 do
                    active_pattern[i] = cur_x
                end
            elseif love.keyboard.isDown("w") then
                save_table = bitser.loads(love.filesystem.read(filename .. cur_x))
                notes[cur_y] = save_table[1][cur_y]
                instrument[cur_y] = save_table[2][cur_y]
                for y, row in ipairs(save_table[3]) do
                    plocks[y][cur_y] = row[cur_y]
                end
                reverb = save_table[4]
                tempo = save_table[5]
                for i = 1, 16 do
                    instrument_change[cur_y][i] = true
                end
                for i = 1, 5 do
                    reverb_change[i] = true
                end
                tempo_change = true
                active_pattern[cur_y] = cur_x
            else
                cur_y = decrement(cur_y, 1, 1)
            end
        elseif key == "down" then
            if love.keyboard.isDown("q") then
                save_table = {notes, instrument, plocks, reverb, tempo}
                love.filesystem.write(filename .. cur_x, bitser.dumps(save_table))
                for i = 1, 16 do
                    active_pattern[i] = cur_x
                end
            elseif love.keyboard.isDown("w") then
                save_table = bitser.loads(love.filesystem.read(filename .. cur_x))
                save_table[1][cur_y] = notes[cur_y]
                save_table[2][cur_y] = instrument[cur_y]
                for y, row in ipairs(plocks) do
                    save_table[3][y][cur_y] = row[cur_y]
                end
                save_table[4] = reverb
                save_table[5] = tempo
                love.filesystem.write(filename .. cur_x, bitser.dumps(save_table))
                active_pattern[cur_y] = cur_x
            else
                cur_y = increment(cur_y, 1, 8)
            end
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
                notes[cur_y][cur_x] = notes[cur_y][cur_x] - 2 * notes[cur_y][cur_x]
            else
                canDelete = false
            end
        elseif statePlock then
            if not togglePlock then
                plocks[inst_nb][cur_y][cur_x] = -1
            else
                togglePlock = false
            end
        end
    end
end

function increment(var, value, limit)
    var = var + value
    if var > limit then
        var = limit
    end
    return var
end

function decrement(var, value, limit)
    var = var - value
    if var < limit then
        var = limit
    end
    return var
end
