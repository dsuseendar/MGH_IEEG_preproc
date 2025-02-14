function [trial_timing] = get_timing_for_LangLocVideo(filteredEventTimes, events_table, timeStart)
    table_keys = {'fix', 'word_1', 'word_2', 'word_3', 'word_4', 'word_5', 'word_6', ...
        'word_7', 'word_8', 'word_9', 'word_10', 'word_11', 'word_12', ...
        'preprobe', 'probe', 'extra_probe'};
    
    num_trials = size(events_table, 1);
    trial_timing = cell(num_trials, 1);

    for k = 1:num_trials
        trial_trig_idx = cell(size(table_keys));
        trial_words_idx = cell(size(table_keys));

        % Extract timing information for each event type and adjust relative to timeStart
        for i = 1:length(table_keys)
            if ~isempty(filteredEventTimes{i}) && k <= length(filteredEventTimes{i})
                if (i < length(table_keys))
                    trial_trig_idx{i} = [filteredEventTimes{i}(k) - timeStart, filteredEventTimes{i+1}(k) - timeStart - 1];
                else
                    trial_trig_idx{i} = [filteredEventTimes{i}(k) - timeStart, filteredEventTimes{i}(k) - timeStart];
                end
            else
                trial_trig_idx{i} = [NaN, NaN];
            end
        end

        % Fill in word strings from events_table
        for p = 1:12
            word_col = sprintf('word%d', p);
            trial_words_idx{p+1} = events_table.(word_col){k}; % +1 because 'fix' is the first key
        end

        % Fill in other event strings
        trial_words_idx{1} = 'fixation';
        trial_words_idx{14} = 'preprobe';
        trial_words_idx{15} = events_table.probe{k};
        trial_words_idx{16} = 'extra_probe';

        % Create the timing table for this trial
        pairs_times = cell2mat(trial_trig_idx');
        trial_timing{k,1} = table(table_keys', trial_words_idx', pairs_times(:,1), pairs_times(:,2), 'VariableNames', {'key', 'string', 'start', 'end'});
        
       
    end
end
