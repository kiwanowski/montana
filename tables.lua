local C = require "constants"

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

notes = make_grid(C.NUM_TRACKS, C.NUM_STEPS, C.EMPTY_NOTE)

noteon = make_row(C.NUM_TRACKS, false)

last_note = make_row(C.NUM_TRACKS, 60)

instrument = {}
for i = 1, C.NUM_TRACKS do
    instrument[i] = {0, 150, 128, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

instrument_change = make_grid(C.NUM_TRACKS, C.NUM_PARAMS, true)

plocks = {}
for i = 1, C.NUM_PARAMS do
    plocks[i] = make_grid(C.NUM_TRACKS, C.NUM_STEPS, C.NO_PLOCK)
end

reverb = {128, 128, 0, 0, 128}

reverb_change = {true, true, true, true, true}

active_pattern = make_row(C.NUM_STEPS, C.NO_PLOCK)

save_patterns = make_grid(C.NUM_TRACKS, C.NUM_STEPS, false)

param_name = {"VOLUME ATTACK", "VOLUME DECAY", "VOLUME LEVEL", "SOUND TIMBRE", "SOUND COLOR", "SYNTHESIS MODEL", "FILTER CUTOFF FREQUENCY",
        "FILTER RESONANCE LEVEL", "FILTER TYPE", "REVERB SEND LEVEL", "PITCH ENVELOPE ATTACK", "PITCH ENVELOPE DECAY", "PITCH ENVELOPE AMOUNT",
        "FILTER ENVELOPE ATTACK", "FILTER ENVELOPE DECAY", "FILTER ENVELOPE AMOUNT", "PITCH LFO RATE", "PITCH LFO AMOUNT", "FILTER LFO RATE",
        "FILTER LFO AMOUNT", "SOUND TIMBRE LFO RATE", "SOUND TIMBRE LFO AMOUNT", "SOUND COLOR LFO RATE", "SOUND COLOR LFO AMOUNT", "REVERB TIME",
        "REVERB DAMPING", "REVERB HIGH PASS FILTERING", "REVERB FREEZE", "REVERB DIFFUSION", "TEMPO"}

synth_name = {"CSAW", "MORPH", "SAW_SQUARE", "SINE_TRIANGLE", "BUZZ", "SQUARE_SUB", "SAW_SUB", "SQUARE_SYNC", "SAW_SYNC", "TRIPLE_SAW", "TRIPLE_SQUARE",
        "TRIPLE_TRIANGLE", "TRIPLE_SINE", "TRIPLE_RING_MOD", "SAW_SWARM", "SAW_COMB", "TOY", "DIGITAL_FILTER_LP", "DIGITAL_FILTER_PK", "DIGITAL_FILTER_BP",
        "DIGITAL_FILTER_HP", "VOSIM", "VOWEL", "VOWEL_FOF", "HARMONICS", "FM", "FEEDBACK_FM", "CHAOTIC_FEEDBACK_FM", "PLUCKED", "BOWED", "BLOWN", "FLUTED",
        "STRUCK_BELL", "STRUCK_DRUM", "KICK", "CYMBAL", "SNARE", "WAVETABLES", "WAVE_MAP", "WAVE_LINE", "WAVE_PARAPHONIC" , "FILTERED_NOISE", "TWIN_PEAKS_NOISE",
        "CLOCKED_NOISE", "GRANULAR_CLOUD", "PARTICLE_NOISE" , "DIGITAL_MODULATION", "QUESTION_MARK"}

filter_type = {"LOWPASS", "BANDPASS", "HIGHPASS"}