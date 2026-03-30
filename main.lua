local C = require "constants"
local Osc = require "osc"
local Persistence = require "persistence"
require "tables"
require "keys"
socket = require "socket"

local osc_msg = {"/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso", "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
    "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam"}
local reverb_osc = {"time", "damp", "hpfl", "frez", "diff"}
local midi_notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

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
    udp:setpeername(C.OSC_HOST, C.OSC_PORT)
    
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

    for i, cell in ipairs(noteon) do
        if cell and time > (stepTime / 2) then
            Osc.note_off(udp, i)
            noteon[i] = false
        end
    end

    if time > stepTime then
        step = step + 1
        time = time - stepTime
        if step > C.NUM_STEPS then
            step = 1
        end

        for y, row in ipairs(notes) do
            if row[step] > 0 then
                Osc.note_on(udp, y, notes[y][step])
                for i, cell in ipairs(osc_msg) do
                    if plocks[i][y][step] > C.NO_PLOCK then
                        Osc.send_param(udp, y, cell, plocks[i][y][step])
                        instrument_change[y][i] = true
                    elseif instrument_change[y][i] then
                        Osc.send_param(udp, y, cell, instrument[y][i])
                        instrument_change[y][i] = false
                    end
                end
                noteon[y] = true
            end
        end
    end

    for i, cell in ipairs(reverb_change) do
        if cell then
            Osc.send_reverb(udp, reverb_osc[i], reverb[i])
            reverb_change[i] = false
        end
    end

    if tempo_change then
        Osc.send_tempo(udp, tempo)
        tempo_change = false
    end
end

local function draw_hud()
    love.graphics.print(love.timer.getFPS(), 2, 2)
    love.graphics.print("V100", 680, 2)
end

local function draw_grid()
    local octave = 12
    for y, row in ipairs(notes) do
        for x, cell in ipairs(row) do
            if cell > 0 then
                if not statePlock then
                    love.graphics.print(midi_notes[notes[y][x] % octave + 1] .. math.floor(notes[y][x] / octave) - 1, (x - 1) * C.CELL_SIZE + C.CENTER_X, (y - 1) * C.CELL_SIZE + C.CENTER_Y)
                elseif plocks[inst_nb][y][x] > C.NO_PLOCK then
                    love.graphics.print(plocks[inst_nb][y][x], (x - 1) * C.CELL_SIZE + C.CENTER_X, (y - 1) * C.CELL_SIZE + C.CENTER_Y)
                else
                    love.graphics.print(instrument[y][inst_nb], (x - 1) * C.CELL_SIZE + C.CENTER_X, (y - 1) * C.CELL_SIZE + C.CENTER_Y)
                end
            end
        end
    end
    love.graphics.draw(main_blocks, C.MARGIN, C.MARGIN)
    love.graphics.draw(white_blocks, (step - 1) * C.CELL_SIZE + C.MARGIN, C.MARGIN)
end

local function draw_save()
    love.graphics.draw(save_blocks, C.MARGIN, C.MARGIN)
    for y = 1, C.NUM_TRACKS do
        for x = 1, C.NUM_STEPS do
            if save_patterns[y][x] then
                love.graphics.draw(pink_blocks3, (x - 1) * C.CELL_SIZE + C.MARGIN, (y - 1) * C.CELL_SIZE + C.MARGIN)
            end
            if active_pattern[y] == x then
                love.graphics.draw(white_blocks2, (x - 1) * C.CELL_SIZE + C.MARGIN, (y - 1) * C.CELL_SIZE + C.MARGIN)
            end
        end
    end
end

local function draw_instrument_params()
    for i = 1, C.NUM_STEPS do
        love.graphics.print(instrument[cur_y][i], (i - 1) * C.CELL_SIZE + C.CENTER_X, C.PARAM_ROW_Y)
        if i < 9 then
            love.graphics.print(instrument[cur_y][i + 16], (i - 1) * C.CELL_SIZE + C.CENTER_X, C.PARAM_ROW2_Y)
        elseif i < 14 then
            love.graphics.print(reverb[i - 8], (i - 1) * C.CELL_SIZE + C.CENTER_X, C.PARAM_ROW2_Y)
        elseif i < 15 then
            love.graphics.print(tempo, (i - 1) * C.CELL_SIZE + C.CENTER_X, C.PARAM_ROW2_Y)
        end
    end
end

local function draw_cursor()
    if not stateInstrument or statePlock then
        love.graphics.draw(pink_blocks2, (cur_x - 1) * C.CELL_SIZE + C.MARGIN, (cur_y - 1) * C.CELL_SIZE + C.MARGIN)
    else
        love.graphics.draw(pink_blocks2, (cur_x_instr - 1) * C.CELL_SIZE + C.MARGIN, (cur_y_instr - 1) * C.CELL_SIZE + C.INSTR_BAR_Y)
        local param_idx = cur_x_instr + (cur_y_instr - 1) * C.NUM_STEPS
        if param_idx < 31 then
            love.graphics.print(param_name[param_idx], 2, 610)
        end
        if param_idx == 6 then
            love.graphics.print(synth_name[instrument[cur_y][6] + 1], 146, 610)
        end
        if param_idx == 9 then
            love.graphics.print(filter_type[instrument[cur_y][9] + 1], 111, 610)
        end
        love.graphics.draw(pink_blocks, C.MARGIN, (cur_y - 1) * C.CELL_SIZE + C.MARGIN)
    end
end

function love.draw()
    draw_hud()
    love.graphics.draw(instr_blocks, C.MARGIN, C.INSTR_BAR_Y)
    if not stateSave then
        draw_grid()
        draw_instrument_params()
    else
        draw_save()
    end
    draw_cursor()
end

function check_patterns()
    for i = 1, C.NUM_STEPS do
        local data = Persistence.load_all(filename, i)
        if data == nil then
            Persistence.save_all(filename, i, notes, instrument, plocks, reverb, tempo)
        else
            for y = 1, C.NUM_TRACKS do
                for x = 1, C.NUM_STEPS do
                    if data[1][y][x] > 0 then
                        save_patterns[y][i] = true
                    end
                end
            end
        end
    end
end
