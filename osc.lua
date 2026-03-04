local Osc = {}

function Osc.send(udp, address)
    udp:send(address .. string.char(0))
end

function Osc.send_int(udp, address, value)
    udp:send(address .. string.char(0) .. ",i" .. string.char(0, 0, 0, 0, 0, value))
end

function Osc.note_on(udp, channel, note)
    Osc.send_int(udp, "/" .. channel .. "/nton", note)
end

function Osc.note_off(udp, channel)
    Osc.send(udp, "/" .. channel .. "/ntof")
end

function Osc.send_param(udp, channel, param, value)
    Osc.send_int(udp, "/" .. channel .. param, value)
end

function Osc.send_reverb(udp, param_name, value)
    Osc.send_int(udp, "/r/" .. param_name, value)
end

function Osc.send_tempo(udp, value)
    Osc.send_int(udp, "/t/temp", value)
end

return Osc
