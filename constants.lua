local C = {
    TRACKS         = 8,
    STEPS          = 16,
    PARAMS         = 24,
    REVERB_PARAMS  = 5,
    REVERB_OFFSET  = 8,
    TEMPO_SLOT     = 30,
    PARAM_INSTR_MAX  = 24,
    PARAM_REVERB_MAX = 29,
    PARAM_TEMPO      = 30,
    CELL_SIZE   = 44,
    MARGIN      = 10,
    OCTAVE      = 12,
    WINDOW_SIZE = 720,

    PARAM_LIMITS = {
        [6] = 47,
        [9] = 2,
        [17] = 5, [19] = 5, [21] = 5, [23] = 5,
    },
    DEFAULT_LIMIT = 255,
}

function C.get_param_limit(param_id)
    return C.PARAM_LIMITS[param_id] or C.DEFAULT_LIMIT
end

return C
