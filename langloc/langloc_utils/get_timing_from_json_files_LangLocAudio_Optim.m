function [trial_timing] = get_timing_from_json_files_LangLocAudio_Optim(events_table, audio_align_path, with_wavelet, fs)
    % Extract timing information from JSON files for LangLoc Audio experiments.
    %
    % Args:
    %   events_table (table): Table containing event information
    %   audio_align_path (str): Path to the audio alignment files
    %   with_wavelet (logical): Boolean indicating whether to use wavelet-processed audio
    %   fs (double): Sampling frequency
    %
    % Returns:
    %   trial_timing (cell): Cell array containing trial timing information

    % Define keys for different parts of the trial
    table_keys = {'fix', 'word_1', 'word_2', 'word_3', 'word_4', 'word_5', 'word_6', ...
        'word_7', 'word_8', 'word_9', 'word_10', 'word_11', 'word_12', ...
        'preprobe', 'probe', 'extra_probe'};

    % Initialize arrays to store condition and timing information
    all_condition = cell(size(events_table, 1), 1);
    trial_timing = cell(size(events_table, 1), 2);
    all_timing_diff = zeros(size(events_table, 1), 1);

    % Set audio path and delay based on wavelet processing
    if with_wavelet
        audio_path = fullfile(pwd, 'audio_alignment', 'stimuli_wavelet');
        delay_val = 0.2;
    else
        audio_path = fullfile(pwd, 'audio_alignment', 'stimuli_orig');
        delay_val = 0;
    end

    % Get all audio filenames from the events table
    all_audio_filenames = events_table.final_audio_filename;

    % Loop through each trial in the events table
    for k = 1:size(events_table, 1)
        % Initialize cells to store trigger and word indices
        trial_trig_idx = cell(size(table_keys));
        trial_words_idx = cell(size(table_keys));

        % Extract timing information for the current trial
        trial_trig_start = events_table.trial_onset_natus(k).*fs; 
        trial_trig_end = events_table.trial_ended_natus(k).*fs;
        trial_audio_start = events_table.audio_onset_natus(k).*fs; 
        trial_audio_end = events_table.audio_ended_natus(k).*fs; 
        trial_probe_start = events_table.probe_onset_natus(k).*fs; 
        trial_post_probe_start = trial_trig_end-0.2*fs;

        % Extract trial type (Sentence or Nonword) from the audio filename
        trial_sent_file = erase(all_audio_filenames{k}, '.wav');
        trial_sent_split = strsplit(trial_sent_file, '_');
        sent_type = trial_sent_split{2};
        trial_type = strcmp(sent_type, 'English') * 'S' + strcmp(sent_type, 'Nonsense') * 'N';
        assert(~isempty(trial_type), 'trial_type is unknown!');
        all_condition{k} = trial_type;

        % Load and process audio alignment information from JSON file
        trial_audio_align = strrep(all_audio_filenames{k}, '.wav', '_handfix.json');
        fname = fullfile(audio_align_path, trial_audio_align);
        audio_align = jsondecode(fileread(fname));
        word_align = audio_align.words;
        assert(size(word_align, 1) == 12, 'Unexpected number of words in alignment');

        % Convert word alignment to struct if necessary
        if ~isstruct(word_align)
            field_names = {'case', 'endOffset', 'startOffset', 'word', 'start', 'end'};
            word_align = cell2struct(cellfun(@(x) cellfun(@(y) x.(y), field_names, 'UniformOutput', false), word_align, 'UniformOutput', false), field_names, 2);
        end

        % Apply delay to word alignment times
        for kk = 1:length(word_align)
            word_align(kk).start = word_align(kk).start + delay_val;
            word_align(kk).end = word_align(kk).end + delay_val;
        end

        % Calculate timing difference between original audio and trial audio
        audio_fname = fullfile(audio_path, [trial_sent_file, '.wav']);
        [orig_audio, orig_fs] = audioread(audio_fname);
        orig_aud_ts = length(orig_audio) / orig_fs;
        trial_aud_ts = (trial_audio_end-trial_audio_start) / fs;
        all_timing_diff(k) = (orig_aud_ts - trial_aud_ts) * 1000;

        % Process word alignment for each word in the trial
        for p = 1:size(word_align, 1)
            assert(strcmp(word_align(p).case, 'success'), sprintf('No alignment for word %d in %s', p, trial_sent_file));
            word_st_ts = max(word_align(p).start, eps);
            word_end_ts = word_align(p).end;
            word_idx = [ceil(word_st_ts * fs), floor(word_end_ts * fs)];
            trial_trig_idx{strcmp(table_keys, sprintf('word_%d', p))} = trial_audio_start + word_idx;
            trial_words_idx{strcmp(table_keys, sprintf('word_%d', p))} = word_align(p).word;
        end

        % Set trigger indices for non-word parts of the trial
        trial_trig_idx{strcmp(table_keys, 'fix')} = [trial_trig_start, trial_audio_start - 1];
        trial_trig_idx{strcmp(table_keys, 'preprobe')} = [trial_audio_end, trial_probe_start - 1];
        trial_trig_idx{strcmp(table_keys, 'probe')} = [trial_probe_start, trial_post_probe_start - 1];
        trial_trig_idx{strcmp(table_keys, 'extra_probe')} = [trial_post_probe_start, trial_trig_end];

        % Compile timing information into a table
        pairs_times = cell2mat(trial_trig_idx');
        trial_timing{k,1} = table(table_keys', trial_words_idx', pairs_times(:,1), pairs_times(:,2), 'VariableNames', {'key', 'string', 'start', 'end'});
        trial_timing{k,2} = trial_type;
    end

    %Plot histogram of timing differences
    figure;
    histogram(all_timing_diff);
    xlabel('ms');
    assert(max(abs(all_timing_diff)) < 50, 'Timing difference exceeds 50ms');
end
