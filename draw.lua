local M = {}

local param_name = {
    "VOLUME ATTACK", "VOLUME DECAY", "VOLUME LEVEL", "SOUND TIMBRE", "SOUND COLOR",
    "SYNTHESIS MODEL", "FILTER CUTOFF FREQUENCY", "FILTER RESONANCE LEVEL", "FILTER TYPE",
    "REVERB SEND LEVEL", "PITCH ENVELOPE ATTACK", "PITCH ENVELOPE DECAY",
    "PITCH ENVELOPE AMOUNT", "FILTER ENVELOPE ATTACK", "FILTER ENVELOPE DECAY",
    "FILTER ENVELOPE AMOUNT", "PITCH LFO RATE", "PITCH LFO AMOUNT", "FILTER LFO RATE",
    "FILTER LFO AMOUNT", "SOUND TIMBRE LFO RATE", "SOUND TIMBRE LFO AMOUNT",
    "SOUND COLOR LFO RATE", "SOUND COLOR LFO AMOUNT", "REVERB TIME", "REVERB DAMPING",
    "REVERB HIGH PASS FILTERING", "REVERB FREEZE", "REVERB DIFFUSION", "TEMPO",
}

local synth_name = {
    "CSAW", "MORPH", "SAW_SQUARE", "SINE_TRIANGLE", "BUZZ", "SQUARE_SUB", "SAW_SUB",
    "SQUARE_SYNC", "SAW_SYNC", "TRIPLE_SAW", "TRIPLE_SQUARE", "TRIPLE_TRIANGLE",
    "TRIPLE_SINE", "TRIPLE_RING_MOD", "SAW_SWARM", "SAW_COMB", "TOY", "DIGITAL_FILTER_LP",
    "DIGITAL_FILTER_PK", "DIGITAL_FILTER_BP", "DIGITAL_FILTER_HP", "VOSIM", "VOWEL",
    "VOWEL_FOF", "HARMONICS", "FM", "FEEDBACK_FM", "CHAOTIC_FEEDBACK_FM", "PLUCKED",
    "BOWED", "BLOWN", "FLUTED", "STRUCK_BELL", "STRUCK_DRUM", "KICK", "CYMBAL", "SNARE",
    "WAVETABLES", "WAVE_MAP", "WAVE_LINE", "WAVE_PARAPHONIC", "FILTERED_NOISE",
    "TWIN_PEAKS_NOISE", "CLOCKED_NOISE", "GRANULAR_CLOUD", "PARTICLE_NOISE",
    "DIGITAL_MODULATION", "QUESTION_MARK",
}

local filter_type = {"LOWPASS", "BANDPASS", "HIGHPASS"}

local midi_notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

function M.draw_sequencer(S, assets, C)
    local center_x = 15
    local center_y = 24
    local instr_y  = 684

    for y, row in ipairs(S.notes) do
        for x, cell in ipairs(row) do
            if cell > 0 then
                if not S.statePlock then
                    love.graphics.print(
                        midi_notes[S.notes[y][x] % C.OCTAVE + 1] .. math.floor(S.notes[y][x] / C.OCTAVE) - 1,
                        (x - 1) * C.CELL_SIZE + center_x, (y - 1) * C.CELL_SIZE + center_y)
                elseif S.plocks[S.inst_nb][y][x] > -1 then
                    love.graphics.print(S.plocks[S.inst_nb][y][x],
                        (x - 1) * C.CELL_SIZE + center_x, (y - 1) * C.CELL_SIZE + center_y)
                else
                    love.graphics.print(S.instrument[y][S.inst_nb],
                        (x - 1) * C.CELL_SIZE + center_x, (y - 1) * C.CELL_SIZE + center_y)
                end
            end
        end
    end

    love.graphics.draw(assets.main_blocks, C.MARGIN, C.MARGIN)
    love.graphics.draw(assets.white_blocks, (S.step - 1) * C.CELL_SIZE + C.MARGIN, C.MARGIN)

    for i = 1, C.STEPS do
        love.graphics.print(S.instrument[S.cur_y][i], (i - 1) * C.CELL_SIZE + center_x, 640)
        if i < 9 then
            love.graphics.print(S.instrument[S.cur_y][i + C.STEPS], (i - 1) * C.CELL_SIZE + center_x, instr_y)
        elseif i < 14 then
            love.graphics.print(S.reverb[i - C.REVERB_OFFSET], (i - 1) * C.CELL_SIZE + center_x, instr_y)
        elseif i < 15 then
            love.graphics.print(S.tempo, (i - 1) * C.CELL_SIZE + center_x, instr_y)
        end
    end
end

function M.draw_save(S, assets, C)
    love.graphics.draw(assets.save_blocks, C.MARGIN, C.MARGIN)

    for y = 1, C.TRACKS do
        for x = 1, C.STEPS do
            if S.save_patterns[y][x] then
                love.graphics.draw(assets.pink_blocks3, (x - 1) * C.CELL_SIZE + C.MARGIN, (y - 1) * C.CELL_SIZE + C.MARGIN)
            end
            if S.active_pattern[y] == x then
                love.graphics.draw(assets.white_blocks2, (x - 1) * C.CELL_SIZE + C.MARGIN, (y - 1) * C.CELL_SIZE + C.MARGIN)
            end
        end
    end
end

function M.draw_cursor(S, assets, C)
    if not S.stateInstrument or S.statePlock then
        love.graphics.draw(assets.pink_blocks2, (S.cur_x - 1) * C.CELL_SIZE + C.MARGIN, (S.cur_y - 1) * C.CELL_SIZE + C.MARGIN)
    else
        love.graphics.draw(assets.pink_blocks2, (S.cur_x_instr - 1) * C.CELL_SIZE + C.MARGIN, (S.cur_y_instr - 1) * C.CELL_SIZE + 626)
        local param_idx = S.cur_x_instr + (S.cur_y_instr - 1) * C.STEPS
        if param_idx <= C.PARAM_TEMPO then
            love.graphics.print(param_name[param_idx], 2, 610)
        end
        if param_idx == 6 then
            love.graphics.print(synth_name[S.instrument[S.cur_y][6] + 1], 146, 610)
        end
        if param_idx == 9 then
            love.graphics.print(filter_type[S.instrument[S.cur_y][9] + 1], 111, 610)
        end

        love.graphics.draw(assets.pink_blocks, C.MARGIN, (S.cur_y - 1) * C.CELL_SIZE + C.MARGIN)
    end
end

return M
