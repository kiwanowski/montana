require "tables"
require "keys"
socket = require "socket"

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
    
    local font = love.graphics.newImageFont("font.png", "0123456789ABCDEFG# HIJKLMNOPQRSTUVWXYZ")
    love.graphics.setFont(font)
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)

    main_blocks = love.graphics.newImage("main_blocks.png")
    save_blocks = love.graphics.newImage("save_blocks.png")
    instr_blocks = love.graphics.newImage("instr_blocks.png")
    pink_blocks = love.graphics.newImage("pink.png")
    white_blocks = love.graphics.newImage("white.png")
end

function love.update(deltatime)
    local stepTime = 1 / (tempo * 4 / 60)
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
    local innerCellSize = 39
    local outerCellSize = 44
    local octave = 12
    local midi_notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    local margin = 10
    local margin2 = 11

    love.graphics.setColor(1, 1, 1)

    love.graphics.print(love.timer.getFPS(), 2, 2)

    love.graphics.print("V100", 300, 2)

    love.graphics.draw(instr_blocks, margin, 626)

    if not stateSave then
        for y, row in ipairs(notes) do
            for x, cell in ipairs(row) do
                love.graphics.setColor(1, 1, 1)
                if x == step then
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

        love.graphics.draw(main_blocks, margin, margin)

        love.graphics.draw(white_blocks, (step - 1) * outerCellSize + margin, margin)

        for i = 1, 16 do
            love.graphics.print(instrument[cur_y][i], (i - 1) * outerCellSize + outerCellSize, 180) -- 180 = 9 * 18 + 18
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

        love.graphics.draw(save_blocks, margin, margin)

        for y = 1, 8 do
            for x = 1, 16 do
                if active_pattern[y] == x then
                    love.graphics.rectangle("fill", (x - 1) * outerCellSize + margin, (y - 1) * outerCellSize + margin, innerCellSize, innerCellSize)
                end
            end
        end
    end

    love.graphics.setColor(1, 0, 1)

    if not stateInstrument or statePlock then
        love.graphics.rectangle("line", (cur_x - 1) * outerCellSize + margin2, (cur_y - 1) * outerCellSize + margin2, innerCellSize, innerCellSize)
    else
        love.graphics.rectangle("line", (cur_x_instr - 1) * outerCellSize + margin2, (cur_y_instr - 1) * outerCellSize + 627, innerCellSize, innerCellSize)
        if (cur_x_instr + (cur_y_instr - 1) * 16) < 31 then
            love.graphics.print(param_name[cur_x_instr + (cur_y_instr - 1) * 16], 16, 220)
        end
        if (cur_x_instr + (cur_y_instr - 1) * 16) == 6 then
            love.graphics.print(synth_name[instrument[cur_y][6] + 1], 162, 220)
        end
        love.graphics.draw(pink_blocks, margin, (cur_y - 1) * outerCellSize + margin)
    end
end
