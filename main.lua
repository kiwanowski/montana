local S = require "state"
local C = require "constants"
local osc = require "osc"
local draw = require "draw"
local persistence = require "persistence"
require "keys"
local socket = require "socket"

local assets = {}

function love.load()
    local font = love.graphics.newImageFont("font.png", "0123456789ABCDEFG# HIJKLMNOPQRSTUVWXYZ")
    love.graphics.setFont(font)
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)

    assets.main_blocks   = love.graphics.newImage("main_blocks.png")
    assets.save_blocks   = love.graphics.newImage("save_blocks.png")
    assets.instr_blocks  = love.graphics.newImage("instr_blocks.png")
    assets.pink_blocks   = love.graphics.newImage("pink.png")
    assets.pink_blocks2  = love.graphics.newImage("pink2.png")
    assets.pink_blocks3  = love.graphics.newImage("pink3.png")
    assets.white_blocks  = love.graphics.newImage("white.png")
    assets.white_blocks2 = love.graphics.newImage("white2.png")

    S.udp = socket.udp()
    S.udp:settimeout(0)
    S.udp:setpeername("127.0.0.1", 57120)

    persistence.check_patterns(S)
end

function love.update(deltatime)
    local stepTime = 1 / (S.tempo * 4 / 60)

    S.time = S.time + deltatime

    for i, cell in ipairs(S.noteon) do
        if cell and S.time > (stepTime / 2) then
            osc.send_bare(S.udp, "/" .. i .. "/ntof")
            S.noteon[i] = false
        end
    end

    if S.time > stepTime then
        S.step = S.step + 1
        S.time = S.time - stepTime
        if S.step > C.STEPS then
            S.step = 1
        end

        for y, row in ipairs(S.notes) do
            if row[S.step] > 0 then
                osc.send_int(S.udp, "/" .. y .. "/nton", S.notes[y][S.step])
                for i, addr in ipairs(osc.param_addr) do
                    if S.plocks[i][y][S.step] > -1 then
                        osc.send_int(S.udp, "/" .. y .. addr, S.plocks[i][y][S.step])
                        S.instrument_change[y][i] = true
                    elseif S.instrument_change[y][i] then
                        osc.send_int(S.udp, "/" .. y .. addr, S.instrument[y][i])
                        S.instrument_change[y][i] = false
                    end
                end
                S.noteon[y] = true
            end
        end
    end

    for i, cell in ipairs(S.reverb_change) do
        if cell then
            osc.send_int(S.udp, "/r/" .. osc.reverb_addr[i], S.reverb[i])
            S.reverb_change[i] = false
        end
    end

    if S.tempo_change then
        osc.send_int(S.udp, "/t/temp", S.tempo)
        S.tempo_change = false
    end
end

function love.draw()
    love.graphics.print(love.timer.getFPS(), 2, 2)
    love.graphics.print("V100", 680, 2)
    love.graphics.draw(assets.instr_blocks, C.MARGIN, 626)
    if S.stateSave then
        draw.draw_save(S, assets, C)
    else
        draw.draw_sequencer(S, assets, C)
    end
    draw.draw_cursor(S, assets, C)
end
