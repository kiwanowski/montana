local M = {}

M.param_addr = {
    "/attk", "/rele", "/levl", "/tmbr", "/colr", "/modl", "/freq", "/reso",
    "/ftyp", "/revb", "/peat", "/pede", "/peam", "/feat", "/fede", "/feam",
    "/plrt", "/plam", "/flrt", "/flam", "/tlrt", "/tlam", "/clrt", "/clam",
}

M.reverb_addr = {"time", "damp", "hpfl", "frez", "diff"}

local function pad_address(addr)
    local s = addr .. "\0"
    while #s % 4 ~= 0 do
        s = s .. "\0"
    end
    return s
end

local function encode_int32(value)
    value = math.floor(value)
    if value < 0 then value = value + 0x100000000 end
    local b1 = math.floor(value / 0x1000000) % 0x100
    local b2 = math.floor(value / 0x10000)   % 0x100
    local b3 = math.floor(value / 0x100)     % 0x100
    local b4 = value                         % 0x100
    return string.char(b1, b2, b3, b4)
end

function M.send_int(udp, addr, value)
    udp:send(pad_address(addr) .. ",i\0\0" .. encode_int32(value))
end

function M.send_bare(udp, addr)
    udp:send(pad_address(addr))
end

return M
