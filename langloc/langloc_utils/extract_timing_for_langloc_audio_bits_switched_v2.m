function [all_trial_timing, trial_based_frame] = extract_timing_for_langloc_audio_bits_switched_v2(args)
%EXTRACT_TIMING_FOR_LANGLOC_AUDIO Extract timing for LangLoc audio bits switched
%   [all_trial_timing, trial_based_frame] = extract_timing_for_langloc_audio_bits_switched(Name,Value)
    arguments
        args.trigger (1,:) {mustBeNumeric}
        args.sampling (1,1) {mustBeNumeric}
        args.pre_start (1,1) {mustBeNumeric} = 0
        args.exclusion (1,:) cell = {}
    end

    TrigMat1 = args.trigger;
    sampling_frequency = args.sampling;
    pre_start_ = args.pre_start;
    exclusion_ = args.exclusion;

    % Extract bits from trigger matrix
    bits = num2cell(TrigMat1(:, 1:8), 1);
    [start_expt_bit, start_aud_bit, end_expt_bit, cond_bit, end_aud_bit, probe_bit, fixation_bit, ~] = bits{:};

    % Create expression frame
    expr_frame = start_expt_bit & ~end_expt_bit;
    expr_frame(1:pre_start_) = 0;
    
    % Apply exclusions
    for exc = exclusion_
        expr_frame(exc{1}(1):exc{1}(2)) = 0;
    end

    % Find event timings
    diff_expr = diff([0; expr_frame]);
    event_timings = @(bit) find(diff([0; bit .* expr_frame]) == 1);
    event_endings = @(bit) find(diff([bit .* expr_frame; 0]) == -1);

    fixation_on = event_timings(fixation_bit);
    fixation_off = event_endings(fixation_bit);
    trial_start = event_timings(start_aud_bit) - 0.2 * sampling_frequency;
    trial_end = event_endings(probe_bit) + 0.2 * sampling_frequency;

    % Find audio and probe timings
    audio_start = event_timings(start_aud_bit);
    audio_end = event_endings(start_aud_bit);
    pre_probe_start = event_endings(end_aud_bit);
    probe_start = event_timings(probe_bit);
    probe_end = event_endings(probe_bit);
    post_probe_start = event_endings(probe_bit);

    trial_keys = {audio_start, audio_end, pre_probe_start, probe_start, post_probe_start};
    key_tags = {'audio_start', 'audio_end', 'pre_probe', 'probe', 'post_probe'};
    buffer_idx = 50 * sampling_frequency;

    % Process trial timings
    all_trial_timing = cell(length(trial_start), 2);
    max_trial_time = 0;

    for tr = 1:length(trial_start)
        start_idx = trial_start(tr);
        end_idx = trial_end(find(trial_end > start_idx, 1, 'first'));
        
        tr_key_idx = cellfun(@(x) x((x > start_idx) & (x < end_idx)), trial_keys, 'UniformOutput', false);
        all_trial_timing(tr,:) = {[start_idx, end_idx], tr_key_idx};
        max_trial_time = max(max_trial_time, end_idx);
    end

    trial_based_frame = 1:min(max_trial_time + buffer_idx, length(TrigMat1));
end
