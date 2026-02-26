require "tables"
require "keys"
socket = require "socket"
bitser = require 'bitser'

local string_char = string.char
local math_floor = math.floor

local OSC_MSG = {"/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso",
    "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
    "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam"}
local REVERB_OSC = {"time", "damp", "hpfl", "frez", "diff"}
local MIDI_NOTES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local OUTER_CELL_SIZE = 44
local OCTAVE = 12
local MARGIN = 10
local CENTER_X = 15
local CENTER_Y = 24
local INSTR_Y = 684
local NULL = string_char(0)
local OSC_INT_PREFIX = ",i" .. string_char(0, 0, 0, 0, 0)

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

    for i = 1, #noteon do
        if noteon[i] and time > (stepTime / 2) then
            udp:send("/" .. i .. "/ntof" .. NULL)
            noteon[i] = false
        end
    end

    if time > stepTime then
        step = step + 1
        time = time - stepTime
        if step > 16 then
            step = 1
        end

        for y = 1, #notes do
            if notes[y][step] > 0 then
                udp:send("/" .. y .. "/nton" .. NULL .. OSC_INT_PREFIX .. string_char(notes[y][step]))
                for i = 1, #OSC_MSG do
                    local cell = OSC_MSG[i]
                    if plocks[i][y][step] > -1 then
                        udp:send("/" .. y .. cell .. NULL .. OSC_INT_PREFIX .. string_char(plocks[i][y][step]))
                        instrument_change[y][i] = true
                    elseif instrument_change[y][i] then
                        udp:send("/" .. y .. cell .. NULL .. OSC_INT_PREFIX .. string_char(instrument[y][i]))
                        instrument_change[y][i] = false
                    end
                end
                noteon[y] = true
            end
        end
    end

    for i = 1, #reverb_change do
        if reverb_change[i] then
            udp:send("/r/" .. REVERB_OSC[i] .. NULL .. OSC_INT_PREFIX .. string_char(reverb[i]))
            reverb_change[i] = false
        end
    end

    if tempo_change then
        udp:send("/t/temp" .. NULL .. OSC_INT_PREFIX .. string_char(tempo))
        tempo_change = false
    end
end

function love.draw()
    love.graphics.print(love.timer.getFPS(), 2, 2)

    love.graphics.print("V100", 680, 2)

    love.graphics.draw(instr_blocks, MARGIN, 626)

    if not stateSave then
        for y, row in ipairs(notes) do
            for x, cell in ipairs(row) do
                if cell > 0 then
                    if not statePlock then
                        love.graphics.print(MIDI_NOTES[notes[y][x] % OCTAVE + 1] .. math_floor(notes[y][x] / OCTAVE) - 1, (x - 1) * OUTER_CELL_SIZE + CENTER_X, (y - 1) * OUTER_CELL_SIZE + CENTER_Y)
                    elseif plocks[inst_nb][y][x] > -1 then
                        love.graphics.print(plocks[inst_nb][y][x], (x - 1) * OUTER_CELL_SIZE + CENTER_X, (y - 1) * OUTER_CELL_SIZE + CENTER_Y)
                    else
                        love.graphics.print(instrument[y][inst_nb], (x - 1) * OUTER_CELL_SIZE + CENTER_X, (y - 1) * OUTER_CELL_SIZE + CENTER_Y)
                    end
                end
            end
        end

        love.graphics.draw(main_blocks, MARGIN, MARGIN)

        love.graphics.draw(white_blocks, (step - 1) * OUTER_CELL_SIZE + MARGIN, MARGIN)

        for i = 1, 16 do
            love.graphics.print(instrument[cur_y][i], (i - 1) * OUTER_CELL_SIZE + CENTER_X, 640)
            if i < 9 then
                love.graphics.print(instrument[cur_y][i + 16], (i - 1) * OUTER_CELL_SIZE + CENTER_X, INSTR_Y)
            elseif i < 14 then
                love.graphics.print(reverb[i - 8], (i - 1) * OUTER_CELL_SIZE + CENTER_X, INSTR_Y)
            elseif i < 15 then
                love.graphics.print(tempo, (i - 1) * OUTER_CELL_SIZE + CENTER_X, INSTR_Y)
            end
        end
    else
        love.graphics.draw(save_blocks, MARGIN, MARGIN)

        for y = 1, 8 do
            for x = 1, 16 do
                if save_patterns[y][x] then
                    love.graphics.draw(pink_blocks3, (x - 1) * OUTER_CELL_SIZE + MARGIN, (y - 1) * OUTER_CELL_SIZE + MARGIN)
                end
                if active_pattern[y] == x then
                    love.graphics.draw(white_blocks2, (x - 1) * OUTER_CELL_SIZE + MARGIN, (y - 1) * OUTER_CELL_SIZE + MARGIN)
                end
            end
        end
    end

    if not stateInstrument or statePlock then
        love.graphics.draw(pink_blocks2, (cur_x - 1) * OUTER_CELL_SIZE + MARGIN, (cur_y - 1) * OUTER_CELL_SIZE + MARGIN)
    else
        love.graphics.draw(pink_blocks2, (cur_x_instr - 1) * OUTER_CELL_SIZE + MARGIN, (cur_y_instr - 1) * OUTER_CELL_SIZE + 626)
        if (cur_x_instr + (cur_y_instr - 1) * 16) < 31 then
            love.graphics.print(param_name[cur_x_instr + (cur_y_instr - 1) * 16], 2, 610)
        end
        if (cur_x_instr + (cur_y_instr - 1) * 16) == 6 then
            love.graphics.print(synth_name[instrument[cur_y][6] + 1], 146, 610)
        end
        if (cur_x_instr + (cur_y_instr - 1) * 16) == 9 then
            love.graphics.print(filter_type[instrument[cur_y][9] + 1], 111, 610)
        end
        love.graphics.draw(pink_blocks, MARGIN, (cur_y - 1) * OUTER_CELL_SIZE + MARGIN)
    end
end

function check_patterns()
    for i = 1, 16 do
        savefile = love.filesystem.read(filename .. i)
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
