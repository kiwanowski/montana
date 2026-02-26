require "tables"
require "keys"
socket = require "socket"
bitser = require 'bitser'

-- Constants moved out of per-frame functions
local OSC_MSG = {"/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso", "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
    "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam"}
local REVERB_OSC = {"time", "damp", "hpfl", "frez", "diff"}
local MIDI_NOTES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local OUTER_CELL_SIZE = 44
local MARGIN = 10
local CENTER_X = 15
local CENTER_Y = 24
local INSTR_Y = 684
local OCTAVE = 12
local NULL_BYTE = string.char(0)
local INT_PREFIX = string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0)

-- Cached stepTime, updated only when tempo changes
local stepTime = 1 / (120 * 4 / 60)

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

    stepTime = 1 / (tempo * 4 / 60)

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
    -- Recalculate stepTime only when tempo changes
    if tempo_change then
        stepTime = 1 / (tempo * 4 / 60)
    end

    time = time + deltatime

    local halfStep = stepTime * 0.5
    for i, cell in ipairs(noteon) do
        if cell and time > halfStep then
            udp:send("/" .. i .. "/ntof" .. NULL_BYTE)
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
            local note = row[step]
            if note > 0 then
                udp:send("/" .. y .. "/nton" .. INT_PREFIX .. string.char(note))
                local plock_y = {}
                for i = 1, #OSC_MSG do
                    plock_y[i] = plocks[i][y][step]
                end
                local instr_y_row = instrument[y]
                local ichange_y = instrument_change[y]
                for i, msg in ipairs(OSC_MSG) do
                    local pval = plock_y[i]
                    if pval > -1 then
                        udp:send("/" .. y .. msg .. INT_PREFIX .. string.char(pval))
                        ichange_y[i] = true
                    elseif ichange_y[i] then
                        udp:send("/" .. y .. msg .. INT_PREFIX .. string.char(instr_y_row[i]))
                        ichange_y[i] = false
                    end
                end
                noteon[y] = true
            end
        end
    end

    for i, cell in ipairs(reverb_change) do
        if cell then
            udp:send("/r/" .. REVERB_OSC[i] .. INT_PREFIX .. string.char(reverb[i]))
            reverb_change[i] = false
        end
    end

    if tempo_change then
        udp:send("/t/temp" .. INT_PREFIX .. string.char(tempo))
        tempo_change = false
    end
end

function love.draw()
    love.graphics.print(love.timer.getFPS(), 2, 2)

    love.graphics.print("V100", 680, 2)

    love.graphics.draw(instr_blocks, MARGIN, 626)

    if not stateSave then
        for y, row in ipairs(notes) do
            local px_y = (y - 1) * OUTER_CELL_SIZE + CENTER_Y
            local plock_row = plocks[inst_nb][y]
            local instr_row = instrument[y]
            for x, cell in ipairs(row) do
                if cell > 0 then
                    local px_x = (x - 1) * OUTER_CELL_SIZE + CENTER_X
                    if not statePlock then
                        love.graphics.print(MIDI_NOTES[cell % OCTAVE + 1] .. (math.floor(cell / OCTAVE) - 1), px_x, px_y)
                    elseif plock_row[x] > -1 then
                        love.graphics.print(plock_row[x], px_x, px_y)
                    else
                        love.graphics.print(instr_row[inst_nb], px_x, px_y)
                    end
                end
            end
        end

        love.graphics.draw(main_blocks, MARGIN, MARGIN)

        love.graphics.draw(white_blocks, (step - 1) * OUTER_CELL_SIZE + MARGIN, MARGIN)

        local instr_cur = instrument[cur_y]
        for i = 1, 16 do
            local px_x = (i - 1) * OUTER_CELL_SIZE + CENTER_X
            love.graphics.print(instr_cur[i], px_x, 640)
            if i < 9 then
                love.graphics.print(instr_cur[i + 16], px_x, INSTR_Y)
            elseif i < 14 then
                love.graphics.print(reverb[i - 8], px_x, INSTR_Y)
            elseif i < 15 then
                love.graphics.print(tempo, px_x, INSTR_Y)
            end
        end
    else
        love.graphics.draw(save_blocks, MARGIN, MARGIN)

        for y = 1, 8 do
            local save_row = save_patterns[y]
            for x = 1, 16 do
                local px_x = (x - 1) * OUTER_CELL_SIZE + MARGIN
                local px_y = (y - 1) * OUTER_CELL_SIZE + MARGIN
                if save_row[x] then
                    love.graphics.draw(pink_blocks3, px_x, px_y)
                end
                if active_pattern[y] == x then
                    love.graphics.draw(white_blocks2, px_x, px_y)
                end
            end
        end
    end

    if not stateInstrument or statePlock then
        love.graphics.draw(pink_blocks2, (cur_x - 1) * OUTER_CELL_SIZE + MARGIN, (cur_y - 1) * OUTER_CELL_SIZE + MARGIN)
    else
        love.graphics.draw(pink_blocks2, (cur_x_instr - 1) * OUTER_CELL_SIZE + MARGIN, (cur_y_instr - 1) * OUTER_CELL_SIZE + 626)
        local cursor_idx = cur_x_instr + (cur_y_instr - 1) * 16
        if cursor_idx < 31 then
            love.graphics.print(param_name[cursor_idx], 2, 610)
        end
        if cursor_idx == 6 then
            love.graphics.print(synth_name[instrument[cur_y][6] + 1], 146, 610)
        end
        if cursor_idx == 9 then
            love.graphics.print(filter_type[instrument[cur_y][9] + 1], 111, 610)
        end
        love.graphics.draw(pink_blocks, MARGIN, (cur_y - 1) * OUTER_CELL_SIZE + MARGIN)
    end
end

function check_patterns()
    for i = 1, 16 do
        local savefile = love.filesystem.read(filename .. i)
        if savefile == nil then
            local save_table = {notes, instrument, plocks, reverb, tempo}
            love.filesystem.write(filename .. i, bitser.dumps(save_table))
        else
            local save_table = bitser.loads(savefile)
            local tbl1 = save_table[1]
            for y = 1, 8 do
                local tbl1_y = tbl1[y]
                for x = 1, 16 do
                    if tbl1_y[x] > 0 then
                        save_patterns[y][i] = true
                    end
                end
            end
        end
    end
end
