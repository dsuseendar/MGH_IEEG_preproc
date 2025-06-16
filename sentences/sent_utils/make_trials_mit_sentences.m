function [trial_timing] = make_trials_mit_sentences(event_table, fs)
%MAKE_TRIALS_MIT_SENTENCES Build trial timing for MIT Sentences experiment

if istable(event_table)
    event_table = table2struct(event_table);
end

trial_timing_keys = {'key', 'string', 'start', 'end'};
trial_timing = cell(length(event_table), 1);

for iTrial = 1:length(event_table)
    trial_timing_struct = struct();
    % for i = 1:length(trial_timing_keys)
    %     trial_timing_struct(i).(trial_timing_keys{i}) = [];
    % end

    % --- 1. AUDIO PRESENTATION ---
    trial_timing_struct(1).key    = 'audio';
    trial_timing_struct(1).string = event_table(iTrial).sentence;
    trial_timing_struct(1).start  = int64(event_table(iTrial).audio_onset_natus * fs  + 1);
    trial_timing_struct(1).end    = int64(event_table(iTrial).audio_ended_natus * fs );

    % --- 2. BEHAVIOR PROBE (if present) ---
    trial_timing_struct(2).key    = 'probe';
    if isfield(event_table, 'behavior_probe') && ~isempty(event_table(iTrial).behavior_probe) && ~isnan(event_table(iTrial).probe_onset_natus)
        trial_timing_struct(2).string = event_table(iTrial).behavior_probe;
        trial_timing_struct(2).start  = int64(event_table(iTrial).probe_onset_natus * fs  + 1);
        % End at response onset or trial end
        if ~isnan(event_table(iTrial).response_onset_natus)
            trial_timing_struct(2).end = int64(event_table(iTrial).response_onset_natus * fs );
        else
            trial_timing_struct(2).end = int64(event_table(iTrial).trial_ended_natus * fs );
        end
    else
        trial_timing_struct(2).string = '';
        trial_timing_struct(2).start  = NaN;
        trial_timing_struct(2).end    = NaN;
    end

    % --- 3. RESPONSE PERIOD ---
    trial_timing_struct(3).key    = 'response';
    trial_timing_struct(3).string = event_table(iTrial).response_key;
    if ~isnan(event_table(iTrial).response_onset_natus)
        trial_timing_struct(3).start = int64(event_table(iTrial).response_onset_natus * fs  + 1);
        trial_timing_struct(3).end   = int64(event_table(iTrial).trial_ended_natus * fs );
    else
        trial_timing_struct(3).start = NaN;
        trial_timing_struct(3).end   = NaN;
    end

    trial_timing{iTrial} = struct2table(trial_timing_struct);
end

trial_timing = trial_timing';

% % --- Adjust event_table timing fields ---
% event_table_modified = event_table;
% fields_to_adjust = {'trial_onset_natus', 'audio_onset_natus', 'audio_ended_natus', ...
%                     'probe_onset_natus', 'response_onset_natus', 'trial_ended_natus'};
% for iTrial = 1:length(event_table)
%     for f = 1:length(fields_to_adjust)
%         fld = fields_to_adjust{f};
%         if isfield(event_table_modified, fld) && ~isnan(event_table(iTrial).(fld))
%             event_table_modified(iTrial).(fld) = event_table(iTrial).(fld) - timeStart/fs;
%         end
%     end
% end

end
