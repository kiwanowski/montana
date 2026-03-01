require "tables"
require "keys"
socket = require "socket"
bitser = require 'bitser'

local OSC_MSG = {"/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso",
    "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
    "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam"}
local REVERB_OSC = {"time", "damp", "hpfl", "frez", "diff"}
local OUTER_CELL = 44
local OCTAVE = 12
local MIDI_NOTES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local MARGIN = 10
local CENTER_X = 15
local CENTER_Y = 24
local INSTR_Y = 684

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
    filename = "save"
    
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername("127.0.0.1", 57120)

    osc_prefix = {}
    for y = 1, 8 do
        osc_prefix[y] = "/" .. y
    end

    local font = love.graphics.newImageFont("font.png", "0123456789ABCDEFG# HIJKLMNOPQRSTUVWXYZ")
    love.graphics.setFont(font)
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)

    main_blocks = love.graphics.newImage("main_blocks.png")
    save_blocks = love.graphics.newImage("save_blocks.png")
    instr_blocks = love.graphics.newImage("instr_blocks.png")
    pink_blocks = love.graphics.newImage("pink.png")
    pink_blocks2 = love.graphics.newImage("pink2.png")
    pink_blocks3 = love.graphics.newImage("pink3.png")
    white_blocks = love.graphics.newImage("white.png")
    white_blocks2 = love.graphics.newImage("white2.png")

    check_patterns()
end

function love.update(deltatime)
    local stepTime = 1 / (tempo * 4 / 60)

    time = time + deltatime

    local halfStep = stepTime / 2
    if time > halfStep then
        for i, cell in ipairs(noteon) do
            if cell then
                udp:send(osc_prefix[i] .. "/ntof" .. string.char(0))
                noteon[i] = false
            end
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
                udp:send(osc_prefix[y] .. "/nton" .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, notes[y][step]))
                for i, cell in ipairs(OSC_MSG) do
                    if plocks[i][y][step] > -1 then
                        udp:send(osc_prefix[y] .. cell .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, plocks[i][y][step]))
                        instrument_change[y][i] = true
                    elseif instrument_change[y][i] then
                        udp:send(osc_prefix[y] .. cell .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, instrument[y][i]))
                        instrument_change[y][i] = false
                    end
                end
                noteon[y] = true
            end
        end
    end

    for i, cell in ipairs(reverb_change) do
        if cell then
            udp:send("/r/" .. REVERB_OSC[i] .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, reverb[i]))
            reverb_change[i] = false
        end
    end

    if tempo_change then
        udp:send("/t/temp" .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, tempo))
        tempo_change = false
    end
end

function love.draw()
    love.graphics.print(love.timer.getFPS(), 2, 2)

    love.graphics.print("V100", 680, 2)

    love.graphics.draw(instr_blocks, MARGIN, 626)

    if not stateSave then
        for y, row in ipairs(notes) do
            local py = (y - 1) * OUTER_CELL + CENTER_Y
            for x, cell in ipairs(row) do
                if cell > 0 then
                    local px = (x - 1) * OUTER_CELL + CENTER_X
                    if not statePlock then
                        love.graphics.print(MIDI_NOTES[notes[y][x] % OCTAVE + 1] .. math.floor(notes[y][x] / OCTAVE) - 1, px, py)
                    elseif plocks[inst_nb][y][x] > -1 then
                        love.graphics.print(plocks[inst_nb][y][x], px, py)
                    else
                        love.graphics.print(instrument[y][inst_nb], px, py)
                    end
                end
            end
        end

        love.graphics.draw(main_blocks, MARGIN, MARGIN)

        love.graphics.draw(white_blocks, (step - 1) * OUTER_CELL + MARGIN, MARGIN)

        for i = 1, 16 do
            love.graphics.print(instrument[cur_y][i], (i - 1) * OUTER_CELL + CENTER_X, 640)
            if i < 9 then
                love.graphics.print(instrument[cur_y][i + 16], (i - 1) * OUTER_CELL + CENTER_X, INSTR_Y)
            elseif i < 14 then
                love.graphics.print(reverb[i - 8], (i - 1) * OUTER_CELL + CENTER_X, INSTR_Y)
            elseif i < 15 then
                love.graphics.print(tempo, (i - 1) * OUTER_CELL + CENTER_X, INSTR_Y)
            end
        end
    else
        love.graphics.draw(save_blocks, MARGIN, MARGIN)

        for y = 1, 8 do
            local py = (y - 1) * OUTER_CELL + MARGIN
            for x = 1, 16 do
                local px = (x - 1) * OUTER_CELL + MARGIN
                if save_patterns[y][x] then
                    love.graphics.draw(pink_blocks3, px, py)
                end
                if active_pattern[y] == x then
                    love.graphics.draw(white_blocks2, px, py)
                end
            end
        end
    end

    if not stateInstrument or statePlock then
        love.graphics.draw(pink_blocks2, (cur_x - 1) * OUTER_CELL + MARGIN, (cur_y - 1) * OUTER_CELL + MARGIN)
    else
        love.graphics.draw(pink_blocks2, (cur_x_instr - 1) * OUTER_CELL + MARGIN, (cur_y_instr - 1) * OUTER_CELL + 626)
        if (cur_x_instr + (cur_y_instr - 1) * 16) < 31 then
            love.graphics.print(param_name[cur_x_instr + (cur_y_instr - 1) * 16], 2, 610)
        end
        if (cur_x_instr + (cur_y_instr - 1) * 16) == 6 then
            love.graphics.print(synth_name[instrument[cur_y][6] + 1], 146, 610)
        end
        if (cur_x_instr + (cur_y_instr - 1) * 16) == 9 then
            love.graphics.print(filter_type[instrument[cur_y][9] + 1], 111, 610)
        end
        love.graphics.draw(pink_blocks, MARGIN, (cur_y - 1) * OUTER_CELL + MARGIN)
    end
end

function check_patterns()
    for i = 1, 16 do
        local savefile = love.filesystem.read(filename .. i)
        local save_table
        if savefile == nil then
            save_table = {notes, instrument, plocks, reverb, tempo}
            love.filesystem.write(filename .. i, bitser.dumps(save_table))
        else
            save_table = bitser.loads(savefile)
            for y = 1, 8 do
                for x = 1, 16 do
                    if save_table[1][y][x] > 0 then
                        save_patterns[y][i] = true
                    end
                end
            end
        end
    end
end
