local M = {}

local function make_row(cols, val)
    local row = {}
    for i = 1, cols do row[i] = val end
    return row
end

local function make_grid(rows, cols, val)
    local grid = {}
    for i = 1, rows do grid[i] = make_row(cols, val) end
    return grid
end

M.notes = make_grid(8, 16, -60)

M.noteon = make_row(8, false)

M.last_note = make_row(8, 60)

M.instrument = {}
for i = 1, 8 do
    M.instrument[i] = {0, 150, 128, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

M.instrument_change = make_grid(8, 24, true)

M.plocks = {}
for i = 1, 24 do
    M.plocks[i] = make_grid(8, 16, -1)
end

M.reverb = {128, 128, 0, 0, 128}

M.reverb_change = {true, true, true, true, true}

M.active_pattern = make_row(16, -1)

M.save_patterns = make_grid(8, 16, false)

M.cur_x = 1
M.cur_y = 1
M.cur_x_instr = 1
M.cur_y_instr = 1
M.step = 1
M.time = 0
M.inst_nb = 1
M.filename = "save"

M.stateInstrument = false
M.statePlock = false
M.stateSave = false
M.canDelete = false
M.togglePlock = false
M.tempo_change = true
M.tempo = 120

return M
