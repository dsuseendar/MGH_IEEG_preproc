 
function events_table_out = sync_natus_timings_for_langloc(events_table, photodiode, microphone, sample_freq)
    % SYNC_NATUS_TIMINGS_FOR_LANGLOC
    % Aligns trial and event timings to Natus system (in seconds) for langloc.
    % User enters run onsets via keyboard (in seconds).
    %
    % Inputs:
    %   events_table: table with trial_onset and audio_ended (in seconds)
    %   photodiode, microphone: vectors of signal values
    %   sample_freq: Natus sampling frequency (Hz)
    % Output:
    %   events_table_out: table with new timing columns (all in seconds)

    unique_runs = unique(events_table.list);
    events_table_out = events_table;

    % Initialize new columns
    events_table_out.trial_onset_natus = nan(height(events_table),1);
    events_table_out.audio_onset_natus = nan(height(events_table),1);
    events_table_out.audio_ended_natus = nan(height(events_table),1);
    events_table_out.probe_onset_natus = nan(height(events_table),1);
    events_table_out.trial_ended_natus = nan(height(events_table),1);

    % Infer time axis from sampling frequency
    n_samples = length(photodiode);
    time_sec = (0:n_samples-1) / sample_freq;

    % Plot photodiode, microphone, and their difference for reference
    figure;
    %plot(time_sec, photodiode, 'g', 'DisplayName', 'Photodiode'); hold on;
    plot(time_sec, microphone, 'r', 'DisplayName', 'Microphone'); hold on;
    plot(time_sec(1:end-1), diff(photodiode) , 'b', 'DisplayName', 'Photodiode - Microphone');
    xlabel('Time (seconds)');
    ylabel('Signal');
    title('Overlay:  Microphone, and Derivative of photodiode');
    legend('show');
    grid on;

    % Prompt user to enter run onsets via keyboard
    disp(['Please enter the Natus run onset (in seconds) for each run, in order, separated by spaces or commas.']);
    disp(['Number of runs to enter: ' num2str(length(unique_runs))]);
    user_input = input('Enter run onsets (seconds): ', 's');
    clicked_onsets = str2num(user_input); %#ok<ST2NM>
    if length(clicked_onsets) ~= length(unique_runs)
        error('Number of entered onsets (%d) does not match number of runs (%d).', length(clicked_onsets), length(unique_runs));
    end

    % Visualize entered onsets
    scatter(clicked_onsets, interp1(time_sec, microphone, clicked_onsets, 'linear', 'extrap'), ...
        100, 'kx', 'LineWidth', 2);

    % Assign and compute all timings for each run
    for i = 1:length(unique_runs)
        run_id = unique_runs(i);
        natus_start_sec = clicked_onsets(i);
        fprintf('\nProcessing Run %d (Natus start = %.3f sec)\n', run_id, natus_start_sec);

        run_trials = find(events_table.list == run_id);
        for idx = run_trials'
            events_table_out.trial_onset_natus(idx) = natus_start_sec + events_table.trial_onset(idx);
            events_table_out.audio_onset_natus(idx) = events_table_out.trial_onset_natus(idx) + 0.2;
            events_table_out.audio_ended_natus(idx) = natus_start_sec + events_table.audio_ended(idx);
            events_table_out.probe_onset_natus(idx) = events_table_out.audio_ended_natus(idx) + 1.2;
            events_table_out.trial_ended_natus(idx) = events_table_out.audio_ended_natus(idx) + 1.8;
        end
        fprintf('Updated %d trials in Run %d\n', length(run_trials), run_id);
    end

    % Visual validation: scatter all Natus trial onsets
    scatter(events_table_out.trial_onset_natus, ...
        interp1(time_sec, microphone, events_table_out.trial_onset_natus, 'linear', 'extrap'), ...
        80, 'green', 'filled');
    legend( 'Microphone', 'Derivative of Photodiode', 'Run Onset Inputs', 'All Trial Onsets (Natus)');
    hold off;
end
