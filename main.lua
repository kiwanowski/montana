require "tables"
require "functions"
socket = require "socket"
local bitser = require 'bitser'

function love.load()
    cur_x = 1
    cur_y = 1
    cur_x_instr = 1
    cur_y_instr = 1
    step = 1
    time = 0
    tempo = 120
    stateInstrument = false
    statePlock = false
    stateSave = false
    canDelete = false
    togglePlock = false
    tempo_change = true
    inst_nb = 1
    
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername("127.0.0.1", 57120)
    
    local font = love.graphics.newImageFont("font.png", "0123456789ABCDEFG#")
    love.graphics.setFont(font)
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)
end

function love.update(deltatime)
    local stepTime = 1 / (tempo * 4 / 60)
    local wiadomosc = ""
    local osc_msg = {"/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso", "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
        "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam"}
    local reverb_osc = {"time", "damp", "hpfl", "frez", "diff"}

    time = time + deltatime

    for i, cell in ipairs(noteon) do
        if cell and time > (stepTime / 2) then
            udp:send("/" .. i .. "/ntof" .. string.char(0))
            noteon[i] = false
        end
    end

    if time > stepTime then
        step = step + 1
        time = time - stepTime
        if step > 16 then
            step = 1
        end

        for y, row in ipairs(notes) do
            if row[step] > 0 then
                udp:send("/" .. y .. "/nton" .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, notes[y][step]))
                for i, cell in ipairs(osc_msg) do
                    if plocks[i][y][step] > -1 then
                        udp:send("/" .. y .. cell .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, plocks[i][y][step]))
                        instrument_change[y][i] = true
                    elseif instrument_change[y][i] then
                        udp:send("/" .. y .. cell .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, instrument[y][i]))
                        instrument_change[y][i] = false
                    end
                end
                noteon[y] = true
            end
        end
    end

    for i, cell in ipairs(reverb_change) do
        if cell then
            udp:send("/r/" .. reverb_osc[i] .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, reverb[i]))
            reverb_change[i] = false
        end
    end

    if tempo_change then
        udp:send("/t/temp" .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, tempo))
        tempo_change = false
    end
end

function love.draw()
    local innerCellSize = 14
    local outerCellSize = 18

    love.graphics.print(love.timer.getFPS())

    if not stateSave then
        local octave = 12
        local midi_notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

        for y, row in ipairs(notes) do
            for x, cell in ipairs(row) do
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
                if x == step then
                    love.graphics.rectangle("fill", (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
                    love.graphics.setColor(0, 0, 0)
                end
                if cell > 0 then
                    if not statePlock then
                        love.graphics.print(midi_notes[notes[y][x] % octave + 1] .. math.floor(notes[y][x] / octave) - 1, (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + outerCellSize)
                    elseif plocks[inst_nb][y][x] > -1 then
                        love.graphics.print(plocks[inst_nb][y][x], (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + outerCellSize)
                    else
                        love.graphics.print(instrument[y][inst_nb], (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + outerCellSize)
                    end
                end
            end
        end

        love.graphics.setColor(1, 1, 1)

        for i = 1, 16 do
            love.graphics.rectangle("line", (i - 1) * outerCellSize + outerCellSize, 176, innerCellSize, innerCellSize) -- 176 = 9 * 18 + 14
            love.graphics.print(instrument[cur_y][i], (i - 1) * outerCellSize + outerCellSize, 180) -- 180 = 9 * 18 + 18
            love.graphics.rectangle("line", (i - 1) * outerCellSize + outerCellSize, 194, innerCellSize, innerCellSize) -- 194 = 10 * 18 + 14
            if i < 9 then
                love.graphics.print(instrument[cur_y][i + 16], (i - 1) * outerCellSize + outerCellSize, 198) -- 198 = 10 * 18 + 18
            elseif i < 14 then
                love.graphics.print(reverb[i - 8], (i - 1) * outerCellSize + outerCellSize, 198) -- 198 = 10 * 18 + 18
            elseif i < 15 then
                love.graphics.print(tempo, (i - 1) * outerCellSize + outerCellSize, 198) -- 198 = 10 * 18 + 18
            end
        end
    else
        love.graphics.setColor(1, 1, 1)
        for y = 1, 8 do
            for x = 1, 16 do
                love.graphics.rectangle("line", (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
                if active_pattern[y] == x then
                    love.graphics.rectangle("fill", (x - 1) * outerCellSize + outerCellSize, (y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
                end
            end
        end
    end

    love.graphics.setColor(1, 0, 1)

    if not stateInstrument or statePlock then
        love.graphics.rectangle("line", (cur_x - 1) * outerCellSize + outerCellSize, (cur_y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
    else
        love.graphics.rectangle("line", (cur_x_instr - 1) * outerCellSize + outerCellSize, (cur_y_instr - 1) * outerCellSize + 176, innerCellSize, innerCellSize)
        for x = 1, 16 do
            love.graphics.rectangle("line", (x - 1) * outerCellSize + outerCellSize, (cur_y - 1) * outerCellSize + innerCellSize, innerCellSize, innerCellSize)
        end
    end
end

function love.keypressed(key)
    inst_nb = (cur_y_instr - 1) * 16 + cur_x_instr
    local filename = "save"

    if not stateSave then
        if not stateInstrument then
            if key == "left" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = decrement(notes[cur_y][cur_x], 12, 12)
                else
                    cur_x = decrement(cur_x, 1, 1)
                end
            elseif key == "right" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = increment(notes[cur_y][cur_x], 12, 120)
                else
                    cur_x = increment(cur_x, 1, 16)
                end
            elseif key == "up" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = increment(notes[cur_y][cur_x], 1, 120)
                else
                    cur_y = decrement(cur_y, 1, 1)
                end
            elseif key == "down" then
                if love.keyboard.isDown("q") then
                    canDelete = true
                    notes[cur_y][cur_x] = decrement(notes[cur_y][cur_x], 1, 12)
                else
                    cur_y = increment(cur_y, 1, 8)
                end
            elseif key == "q" and notes[cur_y][cur_x] < 0 then
                canDelete = true
                notes[cur_y][cur_x] = notes[cur_y][cur_x] - 2 * notes[cur_y][cur_x]
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
                        instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 10, 255)
                        instrument_change[cur_y][inst_nb] = true
                        if instrument[cur_y][6] > 47 then
                            instrument[cur_y][6] = 47
                        elseif instrument[cur_y][9] > 2 then
                            instrument[cur_y][9] = 2
                        elseif instrument[cur_y][17] > 5 then
                            instrument[cur_y][17] = 5
                        elseif instrument[cur_y][19] > 5 then
                            instrument[cur_y][19] = 5
                        elseif instrument[cur_y][21] > 5 then
                            instrument[cur_y][21] = 5
                        elseif instrument[cur_y][23] > 5 then
                            instrument[cur_y][23] = 5
                        end
                    elseif inst_nb < 30 then
                        reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 10, 255)
                        reverb_change[cur_x_instr - 8] = true
                        if reverb[4] > 1 then
                            reverb[4] = 1
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
                        instrument[cur_y][inst_nb] = increment(instrument[cur_y][inst_nb], 1, 255)
                        instrument_change[cur_y][inst_nb] = true
                        if instrument[cur_y][6] > 47 then
                            instrument[cur_y][6] = 47
                        elseif instrument[cur_y][9] > 2 then
                            instrument[cur_y][9] = 2
                        elseif instrument[cur_y][17] > 5 then
                            instrument[cur_y][17] = 5
                        elseif instrument[cur_y][19] > 5 then
                            instrument[cur_y][19] = 5
                        elseif instrument[cur_y][21] > 5 then
                            instrument[cur_y][21] = 5
                        elseif instrument[cur_y][23] > 5 then
                            instrument[cur_y][23] = 5
                        end
                    elseif inst_nb < 30 then
                        reverb[cur_x_instr - 8] = increment(reverb[cur_x_instr - 8], 1, 255)
                        reverb_change[cur_x_instr - 8] = true
                        if reverb[4] > 1 then
                            reverb[4] = 1
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
                    plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 10, 255)
                    if plocks[6][cur_y][cur_x] > 47 then
                        plocks[6][cur_y][cur_x] = 47
                    elseif plocks[9][cur_y][cur_x] > 2 then
                        plocks[9][cur_y][cur_x] = 2
                    elseif plocks[17][cur_y][cur_x] > 5 then
                        plocks[17][cur_y][cur_x] = 5
                    elseif plocks[19][cur_y][cur_x] > 5 then
                        plocks[19][cur_y][cur_x] = 5
                    elseif plocks[21][cur_y][cur_x] > 5 then
                        plocks[21][cur_y][cur_x] = 5
                    elseif plocks[23][cur_y][cur_x] > 5 then
                        plocks[23][cur_y][cur_x] = 5
                    end
                else
                    cur_x = increment(cur_x, 1, 16)
                end
            elseif key == "up" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
                togglePlock = true
                plocks[inst_nb][cur_y][cur_x] = increment(plocks[inst_nb][cur_y][cur_x], 1, 255)
                if plocks[6][cur_y][cur_x] > 47 then
                    plocks[6][cur_y][cur_x] = 47
                elseif plocks[9][cur_y][cur_x] > 2 then
                    plocks[9][cur_y][cur_x] = 2
                elseif plocks[17][cur_y][cur_x] > 5 then
                    plocks[17][cur_y][cur_x] = 5
                elseif plocks[19][cur_y][cur_x] > 5 then
                    plocks[19][cur_y][cur_x] = 5
                elseif plocks[21][cur_y][cur_x] > 5 then
                    plocks[21][cur_y][cur_x] = 5
                elseif plocks[23][cur_y][cur_x] > 5 then
                    plocks[23][cur_y][cur_x] = 5
                end
            elseif key == "down" and notes[cur_y][cur_x] > 0 and love.keyboard.isDown("q") then
                togglePlock = true
                plocks[inst_nb][cur_y][cur_x] = decrement(plocks[inst_nb][cur_y][cur_x], 1, 0)
            elseif key == "q" and plocks[inst_nb][cur_y][cur_x] < 0 then
                togglePlock = true
                plocks[inst_nb][cur_y][cur_x] = 0
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