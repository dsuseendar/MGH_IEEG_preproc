function events_table = extract_behavioral_events_for_sentTask(varargin)
%EXTRACT_BEHAVIORAL_EVENTS_FOR_SENTTASK Processes sentence task behavioral data and assigns corner_id

    p = inputParser;
    addParameter(p, 'behavior_files', []);
    addParameter(p, 'sampling', []);
    addParameter(p, 'filteredEventTimes', []);
    addParameter(p, 'stimulus_lookup_table', []); % Add lookup table parameter
    parse(p, varargin{:});
    
    d_events = p.Results.behavior_files;
    filteredEventTimes = p.Results.filteredEventTimes;
    fs = p.Results.sampling;
    stimulus_lookup = p.Results.stimulus_lookup_table; % Get lookup table

    % Initialize table structure with corner_id
    HeadersOrder = {'session','run','trial','cond_expt','audio_path','sentence',...
        'item_id','sentences_left','sentences_right','response_key',...
        'trial_onset','trial_offset','behavior_probe','response_onset','RT','accuracy','corner_id'}; % Added corner_id
    
    events_table = struct();
    for iField = 1:length(HeadersOrder)
        events_table.(HeadersOrder{iField}) = [];
    end
    
    trialId = 1;
    for bid = 1:length(d_events)
        expt_str = readtable(fullfile(d_events(bid).folder, d_events(bid).name));
        
        for tid = 1:height(expt_str)
            if ~(strcmp(expt_str.cond_expt{tid}, 'behavior') || strcmp(expt_str.cond_expt{tid}, 'sentence'))
                continue
            end
            
            % Populate fields
            events_table(trialId).session = expt_str.session{tid};
            events_table(trialId).run = expt_str.run_id(tid);
            events_table(trialId).trial = expt_str.sent_index(tid);
            events_table(trialId).cond_expt = expt_str.cond_expt(tid);
            events_table(trialId).audio_path = expt_str.audio_path{tid};
            events_table(trialId).sentence = expt_str.sentence{tid};
            events_table(trialId).item_id = expt_str.item_id(tid);
            events_table(trialId).sentences_left = expt_str.sentences_left(tid);
            events_table(trialId).sentences_right = expt_str.sentences_right(tid);
            events_table(trialId).response_key = expt_str.response_key(tid);
            events_table(trialId).trial_onset = expt_str.recorded_time_onset(tid);
            events_table(trialId).trial_offset = expt_str.recorded_time_offset(tid);
            events_table(trialId).behavior_probe = expt_str.behavior_time(tid) + expt_str.recorded_time_onset(tid);
            events_table(trialId).response_onset = expt_str.response_time(tid) + expt_str.recorded_time_onset(tid);
            events_table(trialId).RT = expt_str.RT(tid);
            events_table(trialId).accuracy = expt_str.accuracy(tid);
            
            % Assign corner_id using lookup table
            if ~isempty(stimulus_lookup)
                item_mask = (stimulus_lookup.item_id_control == events_table(trialId).item_id);
                if any(item_mask)
                    events_table(trialId).corner_id = stimulus_lookup.corner_id(item_mask);
                else
                    events_table(trialId).corner_id = NaN; % Handle missing entries
                end
            else
                events_table(trialId).corner_id = NaN;
            end
            
            trialId = trialId + 1;
        end
    end
    
    % Convert to table and handle missing values
    events_table = struct2table(events_table);
    events_table.accuracy(isnan(events_table.accuracy)) = nan;
    events_table.RT(isnan(events_table.RT)) = nan;
end
